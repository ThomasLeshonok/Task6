-- Faker schema for MySQL 8.0+ and MariaDB 10.4+: tables.
-- Every object is prefixed faker_, so the schema can share a database with other applications.
-- Re-running the scripts drops and recreates only faker_ objects.
-- Routines keep the sql_mode they were created with; this fixed mode makes them behave the same on every server.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP TABLE IF EXISTS faker_geo_tiles;
DROP TABLE IF EXISTS faker_geo_regions;
DROP TABLE IF EXISTS faker_lookup_values;
DROP TABLE IF EXISTS faker_lookup_lists;
DROP TABLE IF EXISTS faker_distributions;
DROP TABLE IF EXISTS faker_markov_models;
DROP TABLE IF EXISTS faker_markov_corpus;
DROP TABLE IF EXISTS faker_locales;

-- One row per supported region. Adding a locale = one row here + its lookup lists (no new tables, no code).
CREATE TABLE faker_locales (
    code              VARCHAR(16)  NOT NULL PRIMARY KEY,    -- 'en_US'
    name              VARCHAR(100) NOT NULL,                -- 'English (United States)'
    language_code     CHAR(2)      NOT NULL,                -- ISO 639-1
    country_code      CHAR(2)      NOT NULL,                -- ISO 3166-1 alpha-2
    decimal_separator VARCHAR(4)   NOT NULL,                -- units come from the height/weight format lists
    sort_order        INT          NOT NULL DEFAULT 0
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Catalog of weighted lists: (locale, category, variant) -> list.
-- variant splits one category, e.g. first_name/male and first_name/female; '' when not split.
-- utf8mb4_bin keeps 'Die'/'die' and 'schon'/'schön' apart (needed by the Markov chain and de-duplication).
CREATE TABLE faker_lookup_lists (
    list_id      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    locale       VARCHAR(16)  NOT NULL,
    category     VARCHAR(64)  NOT NULL,
    variant      VARCHAR(255) NOT NULL DEFAULT '',
    item_count   INT          NOT NULL DEFAULT 0,
    total_weight DOUBLE       NOT NULL DEFAULT 0,
    UNIQUE KEY faker_lookup_lists_key (locale, category, variant),
    CONSTRAINT faker_lookup_lists_locale FOREIGN KEY (locale) REFERENCES faker_locales (code) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Every lookup word, format template and Markov transition lives here.
-- cum_weight = running sum of weight inside the list; a draw u in [0,1) selects the first item with
-- cum_weight >= u * total_weight (inverse CDF sampling, one index range scan).
CREATE TABLE faker_lookup_values (
    list_id    INT          NOT NULL,
    item_no    INT          NOT NULL,
    value      VARCHAR(255) NOT NULL,
    weight     DOUBLE       NOT NULL DEFAULT 1,
    cum_weight DOUBLE       NOT NULL DEFAULT 0,
    details    JSON         NULL,                           -- extra fields of compound items (city: region, postal prefix)
    PRIMARY KEY (list_id, item_no),
    KEY faker_lookup_values_pick (list_id, cum_weight),
    CONSTRAINT faker_lookup_values_list FOREIGN KEY (list_id) REFERENCES faker_lookup_lists (list_id) ON DELETE CASCADE,
    CONSTRAINT faker_lookup_values_weight CHECK (weight > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Parameters of continuous attributes drawn from a normal distribution (metric units).
CREATE TABLE faker_distributions (
    locale    VARCHAR(16)  NOT NULL,
    attribute VARCHAR(64)  NOT NULL,                        -- 'height_cm', 'bmi'
    variant   VARCHAR(255) NOT NULL DEFAULT '',             -- gender or ''
    mean      DOUBLE       NOT NULL,
    stddev    DOUBLE       NOT NULL,
    min_value DOUBLE       NOT NULL,
    max_value DOUBLE       NOT NULL,
    PRIMARY KEY (locale, attribute, variant),
    CONSTRAINT faker_distributions_locale FOREIGN KEY (locale) REFERENCES faker_locales (code) ON DELETE CASCADE,
    CONSTRAINT faker_distributions_stddev CHECK (stddev > 0),
    CONSTRAINT faker_distributions_range CHECK (min_value < max_value)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Source texts for the Markov chain, one or more per locale.
CREATE TABLE faker_markov_corpus (
    corpus_id INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    locale    VARCHAR(16)  NOT NULL,
    title     VARCHAR(255) NOT NULL,
    body      MEDIUMTEXT   NOT NULL,
    CONSTRAINT faker_markov_corpus_locale FOREIGN KEY (locale) REFERENCES faker_locales (code) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- One trained chain per locale; transitions are stored as lookup lists (category 'markov', variant = state).
CREATE TABLE faker_markov_models (
    locale      VARCHAR(16) NOT NULL PRIMARY KEY,
    chain_order INT         NOT NULL,
    max_words   INT         NOT NULL,                       -- sentence length cap used when generating
    token_count INT         NOT NULL,
    state_count INT         NOT NULL,
    trained_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT faker_markov_models_locale FOREIGN KEY (locale) REFERENCES faker_locales (code) ON DELETE CASCADE,
    CONSTRAINT faker_markov_models_order CHECK (chain_order > 0 AND max_words > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Parts of a locale's territory used for coordinates: border polygon (lon/lat degrees, Natural Earth) and its
-- bounding box. Locations are sampled equal-area inside a box and kept only when the border contains them.
-- The region is chosen by the weighted lookup list 'geo_region' (weight = spherical area of the box).
CREATE TABLE faker_geo_regions (
    locale    VARCHAR(16)  NOT NULL,
    name      VARCHAR(100) NOT NULL,
    lat_min   DOUBLE       NOT NULL,
    lat_max   DOUBLE       NOT NULL,
    lon_min   DOUBLE       NOT NULL,
    lon_max   DOUBLE       NOT NULL,
    tile_grid INT          NOT NULL,                        -- the box is split into tile_grid x tile_grid tiles
    border    GEOMETRY     NOT NULL,
    PRIMARY KEY (locale, name),
    CONSTRAINT faker_geo_regions_locale FOREIGN KEY (locale) REFERENCES faker_locales (code) ON DELETE CASCADE,
    CONSTRAINT faker_geo_regions_box CHECK (lat_min < lat_max AND lon_min < lon_max),
    CONSTRAINT faker_geo_regions_grid CHECK (tile_grid > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;

-- Precomputed border test: one row per tile of a region's box (row_no counts latitude bands from lat_min, col_no
-- longitude bands from lon_min). A tile wholly inside or outside the border answers the test with `inside` alone;
-- a tile the border crosses keeps the part of the border around it in `border`, a few vertices instead of thousands.
CREATE TABLE faker_geo_tiles (
    locale VARCHAR(16)  NOT NULL,
    region VARCHAR(100) NOT NULL,
    row_no INT          NOT NULL,
    col_no INT          NOT NULL,
    inside BOOLEAN      NOT NULL,                           -- whole tile inside (ignored when border is set)
    border GEOMETRY     NULL,                               -- border clipped to the tile; NULL when not crossed
    PRIMARY KEY (locale, region, row_no, col_no),
    CONSTRAINT faker_geo_tiles_region FOREIGN KEY (locale, region) REFERENCES faker_geo_regions (locale, name)
        ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_bin;
