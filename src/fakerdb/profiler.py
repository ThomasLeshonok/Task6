"""Bottleneck finder: which functions the time goes to, on both sides of the connection.

Database side: faker_profile_users times every step of a generated user and faker_profile_primitives the cost of
one call of each building block (sql/schema/11_profiling.sql). Python side: the real fetch path
(StoredProcedureFaker.users) under cProfile in worker processes, merged, reported per function and per layer
(waiting for the server, PyMySQL, fakerdb, the rest). Processes, not threads: since Python 3.12 cProfile hooks
sys.monitoring, which is shared by all threads, so only one profiler can run at a time.
"""
import cProfile
import pstats
import time
from collections import defaultdict
from collections.abc import Callable
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass, replace
from pathlib import PurePath
from typing import Any

from .benchmark import BenchmarkPlan, Progress, chunks, run_parallel
from .config import Settings
from .database import Database
from .models import BatchRequest
from .ports import QueryRunner, Row
from .repository import StoredProcedureFaker

STEPS_SQL = "CALL faker_profile_users(%(locale)s, %(seed)s, %(start)s, %(count)s, %(about_sentences)s)"
PRIMITIVES_SQL = "CALL faker_profile_primitives(%(locale)s, %(calls)s)"
TOTAL_STEP = "total"

NETWORK = "waiting for the server (socket reads)"
PYMYSQL = "PyMySQL (protocol, row decoding)"
FAKERDB = "fakerdb (repository, models)"
OTHER = "other Python (connection pool, imports, stdlib)"
BUILTIN_FILE = "~"
NETWORK_OBJECTS = ("_socket.socket", "_ssl._SSLSocket")
GENERATED_FILE = "<string>"  # dataclass __init__ and other exec'd code; called from fakerdb here

FunctionKey = tuple[str, int, str]

@dataclass(frozen=True)
class StepCost:
    step: str
    calls: int
    seconds: float

    @property
    def us_per_call(self) -> float:
        return self.seconds / self.calls * 1e6 if self.calls else 0.0

@dataclass(frozen=True)
class PrimitiveCost:
    primitive: str
    calls: int
    us_per_call: float
    us_over_loop: float

@dataclass(frozen=True)
class FunctionCost:
    function: str
    calls: int
    own_seconds: float
    total_seconds: float

def profile_steps(runner: QueryRunner, plan: BenchmarkPlan, progress: Progress,
                  clock: Callable[[], float] = time.perf_counter) -> list[StepCost]:
    """Runs faker_profile_users over positions 0 .. plan.users - 1 in parallel ranges and adds the step times up."""
    seconds: dict[str, float] = defaultdict(float)
    calls: dict[str, int] = defaultdict(int)
    began = clock()
    done = 0

    def work(start: int, count: int) -> list[Row]:
        params = {"locale": plan.locale, "seed": plan.seed, "start": start, "count": count,
                  "about_sentences": plan.about_sentences}
        return runner.fetch(STEPS_SQL, params)

    def finished(rows: list[Row], count: int) -> None:
        nonlocal done
        for row in rows:
            seconds[row["step"]] += float(row["seconds"])
            calls[row["step"]] += int(row["calls"])
        done += count
        progress(done, plan.users, clock() - began)

    run_parallel(work, chunks(plan.users, plan.chunk), plan.workers, finished)
    return [StepCost(step, calls[step], total) for step, total in seconds.items()]

def profile_primitives(runner: QueryRunner, locale: str, calls: int) -> list[PrimitiveCost]:
    rows = runner.fetch(PRIMITIVES_SQL, {"locale": locale, "calls": calls})
    return [PrimitiveCost(r["primitive"], int(r["calls"]), float(r["us_per_call"]), float(r["us_over_loop"]))
            for r in rows]

RawStats = dict[Any, Any]  # cProfile.Profile.stats after create_stats()

class SavedProfile:
    """Profile data sent back by a worker process, in the shape pstats.Stats loads."""

    def __init__(self, stats: RawStats):
        self.stats = stats

    def create_stats(self) -> None:
        pass

_process_faker: list[StoredProcedureFaker] = []

def _open_process_faker(settings: Settings) -> None:
    _process_faker.append(StoredProcedureFaker(Database.from_settings(replace(settings, db_pool_size=1))))

def _profiled_users(request: BatchRequest) -> tuple[int, RawStats]:
    profile = cProfile.Profile()
    users = profile.runcall(_process_faker[0].users, request)
    profile.create_stats()
    return len(users), profile.stats

def profile_python(settings: Settings, plan: BenchmarkPlan, progress: Progress,
                   clock: Callable[[], float] = time.perf_counter) -> tuple[pstats.Stats, float]:
    """Fetches users 0 .. plan.users - 1 through StoredProcedureFaker.users in plan.workers processes, each batch
    under cProfile. Returns the merged profile and the wall time (process start-up included)."""
    if plan.users % plan.chunk:
        raise ValueError("users must be a multiple of chunk")
    requests = [BatchRequest(plan.locale, plan.seed, start // plan.chunk, count, plan.about_sentences)
                for start, count in chunks(plan.users, plan.chunk)]
    began = clock()
    done = 0
    merged: pstats.Stats | None = None
    with ProcessPoolExecutor(plan.workers, initializer=_open_process_faker, initargs=(settings,)) as pool:
        futures = {pool.submit(_profiled_users, request): request for request in requests}
        for future in as_completed(futures):
            count, stats = future.result()
            if count != futures[future].batch_size:
                raise RuntimeError(f"expected {futures[future].batch_size} users, got {count}")
            if merged is None:
                merged = pstats.Stats(SavedProfile(stats))
            else:
                merged.add(SavedProfile(stats))
            done += count
            progress(done, plan.users, clock() - began)
    if merged is None:
        raise ValueError("no users to profile")
    return merged, clock() - began

def function_label(key: FunctionKey) -> str:
    file, line, name = key
    if file == BUILTIN_FILE:
        return name
    path = PurePath(file)
    return f"{'/'.join(path.parts[-2:])}:{line}({name})"

def file_layer(key: FunctionKey) -> str | None:
    """Layer of a Python function by its file; None for C builtins, which take the layer of their caller."""
    file, _, name = key
    if file == BUILTIN_FILE:
        return NETWORK if any(obj in name for obj in NETWORK_OBJECTS) else None
    parts = PurePath(file).parts
    if "pymysql" in parts:
        return PYMYSQL
    if "fakerdb" in parts or file == GENERATED_FILE:
        return FAKERDB
    return OTHER

def top_functions(stats: pstats.Stats, limit: int) -> list[FunctionCost]:
    """The functions with the most own time (time not spent in the functions they call)."""
    rows = [FunctionCost(function_label(key), calls, own, total)
            for key, (_, calls, own, total, _) in stats.stats.items()]  # type: ignore[attr-defined]
    return sorted(rows, key=lambda r: r.own_seconds, reverse=True)[:limit]

def layer_seconds(stats: pstats.Stats) -> dict[str, float]:
    """Own time per layer. A C builtin (str.decode, struct.unpack...) counts for the layer of its caller."""
    totals: dict[str, float] = defaultdict(float)
    for key, (_, _, own, _, callers) in stats.stats.items():  # type: ignore[attr-defined]
        layer = file_layer(key)
        if layer is not None:
            totals[layer] += own
            continue
        if not callers:
            totals[OTHER] += own
            continue
        for caller, caller_stats in callers.items():
            totals[file_layer(caller) or OTHER] += caller_stats[2]
    return dict(sorted(totals.items(), key=lambda item: item[1], reverse=True))
