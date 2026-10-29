import cProfile
import pstats
import re
import threading
from pathlib import Path
from types import SimpleNamespace

import pytest

from fakerdb.benchmark import BenchmarkPlan
from fakerdb.profiler import (FAKERDB, NETWORK, OTHER, PYMYSQL, STEPS_SQL, TOTAL_STEP, SavedProfile, layer_seconds,
                              profile_steps, top_functions)

SCHEMA = Path(__file__).resolve().parents[1] / "sql" / "schema"
PROFILER_ONLY = {"faker_profile_lap", "faker_assert_locale", "faker_open_batch", "faker_open_profile"}

def procedure_calls(sql: str, name: str) -> list[str]:
    body = re.search(rf"CREATE PROCEDURE {name}\(.*?END\$\$", sql, re.S).group(0)
    return re.findall(r"CALL (\w+)\(", body)

def test_profiled_steps_match_the_generator():
    generator = procedure_calls((SCHEMA / "09_api.sql").read_text(encoding="utf-8"), "faker_add_user_to_batch")
    profiled = procedure_calls((SCHEMA / "11_profiling.sql").read_text(encoding="utf-8"), "faker_profile_users")
    assert [name for name in profiled if name not in PROFILER_ONLY] == generator

class StepRunner:
    def __init__(self):
        self.starts = []
        self._lock = threading.Lock()

    def fetch(self, sql, params):
        assert sql == STEPS_SQL
        with self._lock:
            self.starts.append(params["start"])
        count = params["count"]
        return [{"step": "faker_random_email", "calls": count, "seconds": count * 0.01},
                {"step": TOTAL_STEP, "calls": count, "seconds": count * 0.02}]

def test_profile_steps_adds_up_every_range():
    runner = StepRunner()
    progress = []
    plan = BenchmarkPlan("de_DE", 2_500, 7, 1_000, 3, 2)
    steps = profile_steps(runner, plan, lambda done, total, elapsed: progress.append(done))
    assert sorted(runner.starts) == [0, 1_000, 2_000]
    assert [s.step for s in steps] == ["faker_random_email", TOTAL_STEP]
    assert steps[0].calls == 2_500 and steps[0].seconds == pytest.approx(25.0)
    assert steps[1].us_per_call == pytest.approx(20_000)
    assert sorted(progress)[-1] == 2_500

PYMYSQL_FILE = "/venv/Lib/site-packages/pymysql/connections.py"
FAKERDB_FILE = "/project/src/fakerdb/repository.py"
RECV = ("~", 0, "<method 'recv_into' of '_socket.socket' objects>")
DECODE = ("~", 0, "<method 'decode' of 'bytes' objects>")
READ_ROW = (PYMYSQL_FILE, 1343, "_read_row_from_packet")
USERS = (FAKERDB_FILE, 15, "users")
QUEUE = ("/python/Lib/queue.py", 154, "get")

def fake_stats():
    # (primitive calls, calls, own time, cumulative time, callers {caller: (calls, primitive calls, own, cumulative)})
    return SimpleNamespace(stats={
        RECV: (10, 10, 5.0, 5.0, {READ_ROW: (10, 10, 5.0, 5.0)}),
        DECODE: (300, 300, 0.3, 0.3, {READ_ROW: (200, 200, 0.2, 0.2), USERS: (100, 100, 0.1, 0.1)}),
        READ_ROW: (100, 100, 0.5, 6.0, {USERS: (100, 100, 0.5, 6.0)}),
        USERS: (1, 1, 0.25, 6.4, {}),
        QUEUE: (2, 2, 0.05, 0.05, {}),
    })

def test_layers_charge_builtins_to_their_caller():
    layers = layer_seconds(fake_stats())
    assert layers == pytest.approx({NETWORK: 5.0, PYMYSQL: 0.7, FAKERDB: 0.35, OTHER: 0.05})
    assert list(layers) == [NETWORK, PYMYSQL, FAKERDB, OTHER]

def test_top_functions_by_own_time():
    top = top_functions(fake_stats(), 2)
    assert [f.function for f in top] == ["<method 'recv_into' of '_socket.socket' objects>",
                                         "pymysql/connections.py:1343(_read_row_from_packet)"]
    assert top[1].calls == 100 and top[1].total_seconds == 6.0

def test_saved_profiles_merge():
    def work():
        return sum(range(1_000))

    raw = []
    for _ in range(2):
        profile = cProfile.Profile()
        profile.runcall(work)
        profile.create_stats()
        raw.append(profile.stats)
    merged = pstats.Stats(SavedProfile(raw[0]))
    merged.add(SavedProfile(raw[1]))
    calls = {key[2]: value[1] for key, value in merged.stats.items()}
    assert calls["work"] == 2
