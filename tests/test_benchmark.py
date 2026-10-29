import threading

import pytest

from fakerdb.benchmark import (FETCH_SQL, SERVER_SQL, Benchmark, BenchmarkPlan, BenchmarkResult, chunks,
                               format_duration, locale_speeds)

class RecordingRunner:
    def __init__(self, seconds_per_user=0.01):
        self.seconds_per_user = seconds_per_user
        self.calls = []
        self._lock = threading.Lock()

    def fetch(self, sql, params):
        with self._lock:
            self.calls.append((sql, params))
        if sql == SERVER_SQL:
            return [{"seconds": params["count"] * self.seconds_per_user}]
        return [{} for _ in range(params["count"])]

def plan(**changes):
    values = {"locale": "de_DE", "users": 2_500, "seed": 7, "chunk": 1_000, "workers": 3, "about_sentences": 2}
    return BenchmarkPlan(**{**values, **changes})

def test_chunks_cover_every_position_once():
    assert chunks(2_500, 1_000) == [(0, 1_000), (1_000, 1_000), (2_000, 500)]
    assert chunks(1_000, 1_000) == [(0, 1_000)]

def test_server_mode_times_every_range_in_the_database():
    runner = RecordingRunner(seconds_per_user=0.01)
    progress = []
    clock = iter(range(100)).__next__
    result = Benchmark(runner, clock=clock).run(plan(), lambda done, total, elapsed: progress.append(done))
    starts = sorted(params["start"] for _, params in runner.calls)
    assert starts == [0, 1_000, 2_000]
    assert {sql for sql, _ in runner.calls} == {SERVER_SQL}
    assert result.work_seconds == pytest.approx(25.0)
    assert result.ms_per_user == pytest.approx(10.0)
    assert sorted(progress)[-1] == 2_500
    assert result.users_per_second == pytest.approx(2_500 / result.wall_seconds)

def test_fetch_mode_downloads_aligned_batches():
    runner = RecordingRunner()
    Benchmark(runner).run(plan(users=3_000, fetch=True), lambda *_: None)
    assert sorted(params["batch"] for _, params in runner.calls) == [0, 1, 2]
    assert {sql for sql, _ in runner.calls} == {FETCH_SQL}

def test_fetch_mode_needs_whole_batches():
    with pytest.raises(ValueError):
        Benchmark(RecordingRunner()).run(plan(users=2_500, fetch=True), lambda *_: None)

def test_locale_speed_is_all_users_over_all_seconds():
    results = [BenchmarkResult(plan(locale="en_US", users=1_000), 10.0, 0.0),
               BenchmarkResult(plan(locale="en_US", users=9_000), 30.0, 0.0),
               BenchmarkResult(plan(locale="de_DE", users=2_000), 4.0, 0.0)]
    assert locale_speeds(results) == {"en_US": pytest.approx(250.0), "de_DE": pytest.approx(500.0)}

@pytest.mark.parametrize("seconds, text", [(4.24, "4.2 s"), (59.4, "59.4 s"), (61, "1 min 01 s"),
                                           (3_725, "1 h 02 min 05 s")])
def test_format_duration(seconds, text):
    assert format_duration(seconds) == text
