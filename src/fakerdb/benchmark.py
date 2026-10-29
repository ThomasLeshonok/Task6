import time
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass

from .ports import QueryRunner

SERVER_SQL = "CALL faker_benchmark_users(%(locale)s, %(seed)s, %(start)s, %(count)s, %(about_sentences)s)"
FETCH_SQL = "CALL faker_generate_users(%(locale)s, %(seed)s, %(batch)s, %(count)s, %(about_sentences)s)"

Progress = Callable[[int, int, float], None]

@dataclass(frozen=True)
class BenchmarkPlan:
    locale: str
    users: int
    seed: int
    chunk: int
    workers: int
    about_sentences: int
    fetch: bool = False

@dataclass(frozen=True)
class BenchmarkResult:
    plan: BenchmarkPlan
    wall_seconds: float
    work_seconds: float

    @property
    def users_per_second(self) -> float:
        return self.plan.users / self.wall_seconds

    @property
    def ms_per_user(self) -> float:
        return self.work_seconds / self.plan.users * 1000

def locale_speeds(results: list[BenchmarkResult]) -> dict[str, float]:
    """Average users per second of each locale over all its runs: all its users / all their wall seconds."""
    users: dict[str, int] = {}
    seconds: dict[str, float] = {}
    for r in results:
        users[r.plan.locale] = users.get(r.plan.locale, 0) + r.plan.users
        seconds[r.plan.locale] = seconds.get(r.plan.locale, 0.0) + r.wall_seconds
    return {locale: users[locale] / seconds[locale] for locale in users}

def format_duration(seconds: float) -> str:
    minutes, whole_seconds = divmod(round(seconds), 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours} h {minutes:02d} min {whole_seconds:02d} s"
    if minutes:
        return f"{minutes} min {whole_seconds:02d} s"
    return f"{seconds:.1f} s"

def chunks(total: int, size: int) -> list[tuple[int, int]]:
    return [(start, min(size, total - start)) for start in range(0, total, size)]

def run_parallel[T](work: Callable[[int, int], T], ranges: list[tuple[int, int]], workers: int,
                    finished: Callable[[T, int], None]) -> None:
    """Runs work(start, count) for every range on `workers` threads, calling finished(result, count) as each ends."""
    pool = ThreadPoolExecutor(max_workers=workers)
    try:
        futures = {pool.submit(work, start, count): count for start, count in ranges}
        for future in as_completed(futures):
            finished(future.result(), futures[future])
    except BaseException:
        pool.shutdown(wait=False, cancel_futures=True)
        raise
    pool.shutdown()

class Benchmark:
    def __init__(self, runner: QueryRunner, clock: Callable[[], float] = time.perf_counter):
        self._runner = runner
        self._clock = clock

    def _server_chunk(self, plan: BenchmarkPlan, start: int, count: int) -> float:
        params = {"locale": plan.locale, "seed": plan.seed, "start": start, "count": count,
                  "about_sentences": plan.about_sentences}
        return float(self._runner.fetch(SERVER_SQL, params)[0]["seconds"])

    def _fetch_chunk(self, plan: BenchmarkPlan, start: int, count: int) -> float:
        params = {"locale": plan.locale, "seed": plan.seed, "batch": start // plan.chunk, "count": count,
                  "about_sentences": plan.about_sentences}
        began = self._clock()
        rows = self._runner.fetch(FETCH_SQL, params)
        if len(rows) != count:
            raise RuntimeError(f"expected {count} users, got {len(rows)}")
        return self._clock() - began

    def run(self, plan: BenchmarkPlan, progress: Progress) -> BenchmarkResult:
        if plan.fetch and plan.users % plan.chunk:
            raise ValueError("fetch mode needs users to be a multiple of chunk")
        work = self._fetch_chunk if plan.fetch else self._server_chunk
        began = self._clock()
        done = 0
        work_seconds = 0.0

        def finished(seconds: float, count: int) -> None:
            nonlocal done, work_seconds
            work_seconds += seconds
            done += count
            progress(done, plan.users, self._clock() - began)

        run_parallel(lambda start, count: work(plan, start, count), chunks(plan.users, plan.chunk), plan.workers,
                     finished)
        return BenchmarkResult(plan, self._clock() - began, work_seconds)
