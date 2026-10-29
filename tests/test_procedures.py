"""Stored procedure behaviour against a real database (skipped when DATABASE_URL is unreachable)."""
import math
import re
import statistics

import pymysql
import pytest

from fakerdb.connection import connection_args
from fakerdb.models import BatchRequest, TextRequest

SAMPLE = 10_000
LOCATION_SAMPLE = 2_000
BORDER_CHECK_SAMPLE = 300
TILE_CHECK_SAMPLE = 2_000
AGREEMENT_DRAWS = 8          # client-side checks: a few round trips each, slow against a hosted database
AGREEMENT_SENTENCES = 1
EMAIL_RX = re.compile(r"^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]+$")
RING_RX = re.compile(r"\(([^()]+)\)")
REGIONS_SQL = """
    SELECT name, lat_min, lat_max, lon_min, lon_max, ST_AsText(border) AS wkt
    FROM faker_geo_regions WHERE locale = %(locale)s"""

@pytest.fixture(scope="module")
def session(db, settings):
    """One connection, so OUT parameters can be read back through session variables."""
    conn = pymysql.connect(**connection_args(settings))
    yield conn
    conn.close()

def out(session, call, params, names):
    """Runs CALL with @-variables as OUT arguments and returns their values."""
    with session.cursor() as cursor:
        cursor.execute(call, params)
        cursor.execute("SELECT " + ", ".join(f"@{name} AS {name}" for name in names))
        return cursor.fetchone()

def batch(locale="en_US", seed=42, index=0, size=10):
    return BatchRequest(locale, seed, index, size, 2)

def regions(db, locale):
    return db.fetch(REGIONS_SQL, {"locale": locale})

def in_box(region, lat, lon):
    return region["lat_min"] <= lat <= region["lat_max"] and region["lon_min"] <= lon <= region["lon_max"]

def rings(wkt):
    return [[tuple(map(float, point.split())) for point in ring.split(",")] for ring in RING_RX.findall(wkt)]

def inside(all_rings, lat, lon):
    """Even-odd ray casting, independent of the database's ST_Contains."""
    crossings = 0
    for ring in all_rings:
        for (x1, y1), (x2, y2) in zip(ring, ring[1:]):
            if (y1 > lat) != (y2 > lat) and lon < x1 + (lat - y1) * (x2 - x1) / (y2 - y1):
                crossings += 1
    return crossings % 2 == 1

def test_locales(faker):
    codes = [loc.code for loc in faker.locales()]
    assert {"en_US", "de_DE"} <= set(codes)

def test_same_arguments_same_users(faker):
    assert faker.users(batch()) == faker.users(batch())

def test_position_does_not_depend_on_batch_size(faker):
    second_batch_of_ten = faker.users(batch(index=1, size=10))
    first_batch_of_twenty = faker.users(batch(index=0, size=20))
    assert second_batch_of_ten == first_batch_of_twenty[10:]
    assert [u.position for u in second_batch_of_ten] == list(range(11, 21))

@pytest.mark.parametrize("change", [{"seed": 43}, {"locale": "de_DE"}, {"index": 1}])
def test_changed_arguments_change_users(faker, change):
    base = {u.full_name for u in faker.users(batch())}
    other = {u.full_name for u in faker.users(batch(**change))}
    assert len(base & other) <= 1

def test_user_fields(faker, db):
    for locale in ("en_US", "de_DE"):
        boxes = regions(db, locale)
        for user in faker.users(batch(locale=locale, size=50)):
            assert EMAIL_RX.match(user.email), user.email
            assert sum(c.isdigit() for c in user.phone) >= 10, user.phone
            assert any(in_box(r, user.latitude, user.longitude) for r in boxes), (user.latitude, user.longitude)
            assert user.full_name and user.address and user.about.endswith((".", "!", "?"))

def test_names_are_varied(faker):
    users = faker.users(batch(size=500))
    assert len({u.full_name for u in users}) >= 495
    assert any("." in u.full_name.split()[0] for u in users)  # some titles
    assert any(len(u.full_name.split()) >= 3 for u in users)  # some middle names or suffixes

def test_unknown_locale_is_rejected(faker):
    with pytest.raises(pymysql.MySQLError, match="Unknown locale"):
        faker.users(batch(locale="xx_XX"))

def test_lookup_tables_are_large(db):
    rows = db.fetch("""
        SELECT locale, category, SUM(item_count) AS items
        FROM faker_lookup_lists
        WHERE category IN ('first_name', 'last_name', 'street_name', 'city')
        GROUP BY locale, category""", {})
    sizes = {(r["locale"], r["category"]): int(r["items"]) for r in rows}
    for locale in ("en_US", "de_DE"):
        combinations = sizes[(locale, "first_name")] * sizes[(locale, "last_name")]
        assert combinations >= 100_000, (locale, combinations)
        assert sizes[(locale, "city")] >= 200 and sizes[(locale, "street_name")] >= 150

def test_geolocation_is_uniform_on_the_sphere(db):
    rows = db.fetch("CALL faker_sample_geolocations(%(seed)s, %(n)s)", {"seed": 1, "n": SAMPLE})
    z = [math.sin(math.radians(r["latitude"])) for r in rows]
    lon = [r["longitude"] for r in rows]
    tolerance = 4 / math.sqrt(SAMPLE)
    # z = sin(latitude) is uniform on [-1, 1]: mean 0, variance 1/3
    assert abs(statistics.fmean(z)) < tolerance
    assert abs(statistics.pvariance(z) - 1 / 3) < tolerance
    # half of the sphere area lies between 30S and 30N (a uniform latitude would give one third)
    assert abs(sum(abs(r["latitude"]) < 30 for r in rows) / SAMPLE - 0.5) < tolerance
    assert abs(statistics.fmean(lon)) < 180 * tolerance

@pytest.mark.parametrize("locale", ["de_DE", "en_US"])
def test_locations_lie_inside_the_country_border(db, locale):
    all_rings = [ring for region in regions(db, locale) for ring in rings(region["wkt"])]
    points = db.fetch("CALL faker_sample_locations(%(locale)s, %(seed)s, %(n)s)",
                      {"locale": locale, "seed": 4, "n": BORDER_CHECK_SAMPLE})
    outside = [(p["latitude"], p["longitude"]) for p in points if not inside(all_rings, p["latitude"], p["longitude"])]
    assert not outside

def test_us_locations_follow_area(db):
    boxes = {r["name"]: r for r in regions(db, "en_US")}
    points = db.fetch("CALL faker_sample_locations('en_US', %(seed)s, %(n)s)", {"seed": 5, "n": LOCATION_SAMPLE})
    share = {name: sum(in_box(box, p["latitude"], p["longitude"]) for p in points) / LOCATION_SAMPLE
             for name, box in boxes.items()}
    # Alaska is about a sixth of the US area, Hawaii a fraction of a percent; uniform boxes would give other shares
    assert 0.12 < share["Alaska"] < 0.22
    assert 0 < share["Hawaii"] < 0.01
    assert share["Contiguous United States"] > 0.75

def test_normal_distribution(db):
    mean, stddev = 170.0, 8.0
    rows = db.fetch("CALL faker_sample_normal(%(seed)s, %(n)s, %(mean)s, %(sd)s)",
                    {"seed": 2, "n": SAMPLE, "mean": mean, "sd": stddev})
    xs = [r["value"] for r in rows]
    within_one_sd = sum(abs(x - mean) < stddev for x in xs) / SAMPLE
    assert abs(statistics.fmean(xs) - mean) < 4 * stddev / math.sqrt(SAMPLE)
    assert abs(statistics.pstdev(xs) / stddev - 1) < 0.03
    assert abs(within_one_sd - 0.6827) < 0.02

def test_weighted_pick_follows_weights(db):
    rows = db.fetch("CALL faker_sample_values('en_US', 'blood_type', '', %(seed)s, %(n)s)", {"seed": 3, "n": SAMPLE})
    share = sum(r["value"] == "O+" for r in rows) / SAMPLE
    assert abs(share - 0.374) < 0.02

def test_markov_text_is_reproducible_and_localized(faker):
    request = TextRequest("de_DE", 5, 2, 3)
    paragraphs = faker.text(request)
    assert paragraphs == faker.text(request) and len(paragraphs) == 2
    words = set(" ".join(paragraphs).lower().replace(",", "").replace(".", "").split())
    assert words & {"und", "die", "der", "das", "ist", "mit"}
    assert faker.text(TextRequest("de_DE", 6, 2, 3)) != paragraphs

def test_profile_users_times_every_step(db):
    rows = db.fetch("CALL faker_profile_users('de_DE', 42, 0, 20, 2)", {})
    steps = {r["step"]: r for r in rows}
    total = steps.pop("total")
    assert total["calls"] == 20 and total["seconds"] > 0
    assert sum(r["seconds"] for r in steps.values()) == pytest.approx(total["seconds"], rel=0.05)
    assert {"faker_random_email", "faker_markov_text", "faker_random_location"} <= set(steps)

def test_profile_primitives_cover_the_building_blocks(db):
    rows = db.fetch("CALL faker_profile_primitives('en_US', 3)", {})
    costs = {r["primitive"]: r for r in rows}
    assert costs["empty_loop"]["us_over_loop"] == 0
    assert {"call_overhead", "faker_pick", "faker_to_ascii", "faker_markov_sentence"} <= set(costs)
    assert all(r["calls"] == 3 and r["us_per_call"] > 0 for r in rows)

def test_fill_digits_draws_like_random_int(session):
    template = "%#-##x%"
    filled = out(session, "CALL faker_fill_digits(MD5('k'), 'mask', %(t)s, @r)", {"t": template}, ["r"])["r"]
    assert len(filled) == len(template) and filled[2] == "-" and filled[5] == "x"
    for position, char in enumerate(template, start=1):
        if char in "#%":
            low = 0 if char == "#" else 1
            digit = out(session, "CALL faker_random_int(MD5('k'), %(s)s, %(low)s, 9, @d)",
                        {"s": f"mask.{position}", "low": low}, ["d"])["d"]
            assert filled[position - 1] == str(digit)

def test_uniform_is_the_top_bits_of_random_bits(session):
    for n in range(AGREEMENT_DRAWS):
        row = out(session, "CALL faker_random_bits(MD5('k'), %(s)s, @b)", {"s": f"s{n}"}, ["b"])
        uniform = out(session, "CALL faker_random_uniform(MD5('k'), %(s)s, @u)", {"s": f"s{n}"}, ["u"])["u"]
        assert uniform == (int(row["b"]) >> 11) / 2**53

@pytest.mark.parametrize("category, variant", [("last_name", ""), ("first_name", "female"), ("city", "")])
def test_random_value_and_item_pick_with_the_uniform(session, category, variant):
    """faker_random_value and faker_random_item compute the uniform themselves; it must be faker_random_uniform's."""
    args = {"c": category, "v": variant}
    for n in range(AGREEMENT_DRAWS):
        args["s"] = f"s{n}"
        with session.cursor() as cursor:
            cursor.execute("CALL faker_random_uniform(MD5('k'), %(s)s, @u)", args)
            cursor.execute("CALL faker_pick('en_US', %(c)s, %(v)s, @u, @picked, @d)", args)
            cursor.execute("CALL faker_random_value(MD5('k'), %(s)s, 'en_US', %(c)s, %(v)s, @value)", args)
            cursor.execute("CALL faker_random_item(MD5('k'), %(s)s, 'en_US', %(c)s, %(v)s, @item, @d)", args)
            cursor.execute("SELECT @picked AS picked, @value AS value, @item AS item")
            row = cursor.fetchone()
        assert row["picked"] is not None and row["picked"] == row["value"] == row["item"]

def test_markov_sentence_walks_the_chain_with_random_value(session):
    """faker_markov_sentence writes out faker_random_value, faker_is_sentence_end and faker_markov_next_state."""
    locale = "de_DE"  # umlauts and German quotes after sentence ends
    with session.cursor() as cursor:
        cursor.execute("SELECT chain_order, max_words FROM faker_markov_models WHERE locale = %(l)s", {"l": locale})
        model = cursor.fetchone()
    for sentence_no in range(AGREEMENT_SENTENCES):
        stream = f"walk{sentence_no}"
        args = {"l": locale, "o": model["chain_order"]}
        tokens = []
        with session.cursor() as cursor:
            cursor.execute("CALL faker_markov_start(%(o)s, @state)", args)
            for i in range(1, model["max_words"] + 1):
                args["s"] = f"{stream}.{i}"
                cursor.execute("CALL faker_random_value(MD5('k'), %(s)s, %(l)s, 'markov', @state, @token)", args)
                cursor.execute("CALL faker_is_sentence_end(@token, @end)")
                cursor.execute("CALL faker_markov_next_state(@state, @token, %(o)s, @state)", args)
                cursor.execute("SELECT @token AS token, @end AS end")
                row = cursor.fetchone()
                if row["token"] is None:
                    break
                tokens.append(row["token"])
                if row["end"]:
                    break
        walked = out(session, "CALL faker_finish_sentence(%(w)s, @r)", {"w": " ".join(tokens).strip(" ")}, ["r"])["r"]
        sentence = out(session, "CALL faker_markov_sentence(MD5('k'), %(s)s, %(l)s, @r)",
                       {"s": stream, "l": locale}, ["r"])["r"]
        assert sentence == walked

@pytest.mark.parametrize("locale", ["de_DE", "en_US"])
def test_border_tiles_answer_like_the_whole_border(db, locale):
    rows = db.fetch("CALL faker_sample_border_checks(%(locale)s, %(seed)s, %(n)s)",
                    {"locale": locale, "seed": 6, "n": TILE_CHECK_SAMPLE})
    assert [r for r in rows if r["by_tiles"] != r["by_border"]] == []
    assert {r["by_border"] for r in rows} == {0, 1}

@pytest.mark.parametrize("locale, text, ascii", [
    ("de_DE", "Müller-Lüdenscheidt", "muellerluedenscheidt"), ("de_DE", "Groß", "gross"),
    ("en_US", "José Peña", "josepena"), ("en_US", "O'Brien", "obrien"), ("en_US", "Smith", "smith"),
    ("en_US", "Weiß", "wei"),  # no rule for ß in en_US: dropped
    ("de_DE", "😀 Müller", "mueller"),  # 4-byte character first (MariaDB's REGEXP_SUBSTR returns '?' for it)
])
def test_to_ascii(session, locale, text, ascii):
    assert out(session, "CALL faker_to_ascii(%(l)s, %(t)s, @r)", {"l": locale, "t": text}, ["r"])["r"] == ascii

def test_pick_of_a_missing_list_is_null(session):
    row = out(session, "CALL faker_pick('en_US', 'no_such_list', '', 0.5, @v, @d)", {}, ["v", "d"])
    assert row == {"v": None, "d": None}
