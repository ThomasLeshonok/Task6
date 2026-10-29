from pathlib import Path

from .ports import ScriptRunner
from .sql_script import split_statements

SCHEMA_DIR = "schema"
LOCALES_DIR = "locales"
SQL_PATTERN = "*.sql"

def sql_files(sql_dir: Path) -> list[Path]:
    schema = sorted((sql_dir / SCHEMA_DIR).glob(SQL_PATTERN))
    locales = sorted((sql_dir / LOCALES_DIR).glob(f"*/{SQL_PATTERN}"))
    return schema + locales

def install(runner: ScriptRunner, sql_dir: Path) -> list[Path]:
    files = sql_files(sql_dir)
    if not files:
        raise FileNotFoundError(f"No SQL files under {sql_dir}")
    runner.run_statements([s for f in files for s in split_statements(f.read_text(encoding="utf-8"))])
    return files
