"""Measures fake user generation speed (users per second) of the stored procedures.

By default it starts a new, empty database server on a free local port (XAMPP's MariaDB or any mariadbd / mysqld),
installs the schema there, runs the benchmark and deletes the server again; --use-database-url benchmarks the
database in DATABASE_URL instead.

python src/benchmark.py --users 10000 100000 --locales en_US de_DE --workers 6
"""
import argparse
import csv
import os
import sys
import time
from dataclasses import replace
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fakerdb.benchmark import Benchmark, BenchmarkPlan, BenchmarkResult, format_duration, locale_speeds
from fakerdb.config import ROOT, Settings
from fakerdb.database import Database
from fakerdb.installer import install
from fakerdb.local_server import LocalServer, find_server
from fakerdb.repository import StoredProcedureFaker

DEFAULT_USERS = [10_000]
DEFAULT_CHUNK = 1_000
DEFAULT_WORKERS = max(1, (os.cpu_count() or 1) // 2)
LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}
CSV_FIELDS = ["timestamp", "server", "locale", "users", "workers", "chunk", "mode", "seconds", "users_per_second",
              "ms_per_user"]

def parse_args(settings: Settings) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--users", type=int, nargs="+", default=DEFAULT_USERS, help="user counts to generate")
    parser.add_argument("--locales", nargs="+", help="locale codes (default: every locale in the database)")
    parser.add_argument("--workers", type=int, default=DEFAULT_WORKERS,
                        help=f"parallel connections (default: {DEFAULT_WORKERS}, about the CPU core count)")
    parser.add_argument("--chunk", type=int, default=DEFAULT_CHUNK, help="users per procedure call")
    parser.add_argument("--seed", type=int, default=settings.default_seed)
    parser.add_argument("--about-sentences", type=int, default=settings.about_sentences)
    parser.add_argument("--fetch", action="store_true",
                        help="call faker_generate_users and download the rows (end to end) instead of timing only "
                             "the generation inside the database")
    parser.add_argument("--csv", type=Path, help="append results to this CSV file")
    parser.add_argument("--mysqld", help="server binary for the new database server (default: mariadbd or mysqld "
                                         "on PATH, else XAMPP's C:/xampp/mysql/bin/mysqld.exe)")
    parser.add_argument("--use-database-url", action="store_true",
                        help="benchmark the database in DATABASE_URL (schema already installed) instead of a new "
                             "local server")
    parser.add_argument("--allow-remote", action="store_true",
                        help="with --use-database-url: allow a non-local DATABASE_URL (a long run loads a hosted "
                             "database for a long time)")
    return parser.parse_args()

def server_label(db: Database, url: str) -> str:
    version = db.fetch("SELECT VERSION() AS version", {})[0]["version"]
    return f"{version} @ {urlparse(url).hostname}"

def print_progress(locale: str, done: int, total: int, elapsed: float) -> None:
    rate = done / elapsed if elapsed else 0.0
    eta = (total - done) / rate if rate else 0.0
    print(f"\r  {locale}: {done:,}/{total:,} users  {rate:,.0f} users/s  elapsed {elapsed:,.0f} s  "
          f"left ~{eta:,.0f} s   ", end="", flush=True)

def print_table(server: str, results: list[BenchmarkResult]) -> None:
    print(f"\nServer: {server}\n")
    print("| Locale | Users | Workers | Mode | Seconds | Users/s | ms per user (one connection) |")
    print("|--------|------:|--------:|------|--------:|--------:|-----------------------------:|")
    for r in results:
        mode = "fetch" if r.plan.fetch else "in database"
        print(f"| {r.plan.locale} | {r.plan.users:,} | {r.plan.workers} | {mode} | {r.wall_seconds:,.1f} | "
              f"{r.users_per_second:,.0f} | {r.ms_per_user:.1f} |")

def append_csv(path: Path, server: str, results: list[BenchmarkResult]) -> None:
    is_new = not path.exists()
    with path.open("a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
        if is_new:
            writer.writeheader()
        for r in results:
            writer.writerow({
                "timestamp": datetime.now().isoformat(timespec="seconds"), "server": server,
                "locale": r.plan.locale, "users": r.plan.users, "workers": r.plan.workers, "chunk": r.plan.chunk,
                "mode": "fetch" if r.plan.fetch else "database", "seconds": round(r.wall_seconds, 3),
                "users_per_second": round(r.users_per_second, 1), "ms_per_user": round(r.ms_per_user, 2),
            })

def print_summary(results: list[BenchmarkResult], names: dict[str, str], total_seconds: float) -> None:
    if not results:
        return
    generation_seconds = sum(r.wall_seconds for r in results)
    print("\nAverage generated users per second:")
    for locale, speed in locale_speeds(results).items():
        print(f"  {names.get(locale, locale)} ({locale}): {speed:,.0f}")
    print(f"  All locales: {sum(r.plan.users for r in results) / generation_seconds:,.0f}")
    print(f"Total time: {format_duration(total_seconds)}, of which generating users "
          f"{format_duration(generation_seconds)}")

def run_benchmarks(settings: Settings, args: argparse.Namespace,
                   install_schema: bool) -> tuple[str, list[BenchmarkResult], dict[str, str]]:
    db = Database.from_settings(replace(settings, db_pool_size=args.workers))
    try:
        server = server_label(db, settings.database_url)
        if install_schema:
            began = time.perf_counter()
            install(db, settings.sql_dir)
            print(f"Installed the schema in {format_duration(time.perf_counter() - began)}")
        names = {loc.code: loc.name for loc in StoredProcedureFaker(db).locales()}
        locales = args.locales or list(names)
        print(f"Benchmarking {server} with {args.workers} worker(s), {args.chunk:,} users per call")
        benchmark = Benchmark(db)
        results = []
        for locale in locales:
            for users in args.users:
                plan = BenchmarkPlan(locale, users, args.seed, args.chunk, args.workers, args.about_sentences, args.fetch)
                results.append(benchmark.run(plan, lambda done, total, elapsed: print_progress(locale, done, total, elapsed)))
                print()
    finally:
        db.close()
    return server, results, names

def main() -> None:
    load_dotenv(ROOT / ".env")
    settings = Settings.from_env()
    args = parse_args(settings)
    began = time.perf_counter()
    if args.use_database_url:
        if urlparse(settings.database_url).hostname not in LOCAL_HOSTS and not args.allow_remote:
            sys.exit("DATABASE_URL is not a local server; add --allow-remote to benchmark it anyway.")
        server, results, names = run_benchmarks(settings, args, install_schema=False)
    else:
        with LocalServer(find_server(args.mysqld)) as local:
            print(f"Started a new database server on port {local.port} ({local.server})")
            local_settings = replace(settings, database_url=local.url, db_ssl_mode="DISABLED", db_ssl_ca="")
            server, results, names = run_benchmarks(local_settings, args, install_schema=True)
    total_seconds = time.perf_counter() - began
    print_table(server, results)
    print_summary(results, names, total_seconds)
    if args.csv:
        append_csv(args.csv, server, results)
        print(f"\nAppended to {args.csv}")

if __name__ == "__main__":
    main()
