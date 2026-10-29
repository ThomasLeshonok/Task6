import os
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Every tunable value lives here; each can be overridden by the environment variable of the same name.
DEFAULTS = {
    "DATABASE_URL": "",
    "DB_SSL_MODE": "",
    "DB_SSL_CA": "",
    "DB_CHARSET": "utf8mb4",
    "DB_DEFAULT_PORT": 3306,
    "DB_CONNECT_TIMEOUT": 10,
    "DB_POOL_SIZE": 4,
    "DB_PING_AFTER_SECONDS": 30,
    "FAKER_SQL_DIR": str(ROOT / "sql"),
    "FAKER_BATCH_SIZE": 10,
    "FAKER_DEFAULT_SEED": 42,
    "FAKER_MAX_SEED": 2**31 - 1,
    "FAKER_ABOUT_SENTENCES": 2,
    "FAKER_TEXT_PARAGRAPHS": 3,
    "FAKER_TEXT_MAX_PARAGRAPHS": 10,
    "FAKER_TEXT_SENTENCES": 4,
    "FAKER_TEXT_MAX_SENTENCES": 12,
    "FAKER_CACHE_ENTRIES": 256,
}

def env_str(name: str) -> str:
    return os.environ.get(name, str(DEFAULTS[name]))

def env_int(name: str) -> int:
    return int(env_str(name))

@dataclass(frozen=True)
class Settings:
    database_url: str
    db_ssl_mode: str
    db_ssl_ca: str
    db_charset: str
    db_default_port: int
    db_connect_timeout: int
    db_pool_size: int
    db_ping_after_seconds: int
    sql_dir: Path
    batch_size: int
    default_seed: int
    max_seed: int
    about_sentences: int
    text_paragraphs: int
    text_max_paragraphs: int
    text_sentences: int
    text_max_sentences: int
    cache_entries: int

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            database_url=env_str("DATABASE_URL"),
            db_ssl_mode=env_str("DB_SSL_MODE"),
            db_ssl_ca=env_str("DB_SSL_CA"),
            db_charset=env_str("DB_CHARSET"),
            db_default_port=env_int("DB_DEFAULT_PORT"),
            db_connect_timeout=env_int("DB_CONNECT_TIMEOUT"),
            db_pool_size=env_int("DB_POOL_SIZE"),
            db_ping_after_seconds=env_int("DB_PING_AFTER_SECONDS"),
            sql_dir=Path(env_str("FAKER_SQL_DIR")),
            batch_size=env_int("FAKER_BATCH_SIZE"),
            default_seed=env_int("FAKER_DEFAULT_SEED"),
            max_seed=env_int("FAKER_MAX_SEED"),
            about_sentences=env_int("FAKER_ABOUT_SENTENCES"),
            text_paragraphs=env_int("FAKER_TEXT_PARAGRAPHS"),
            text_max_paragraphs=env_int("FAKER_TEXT_MAX_PARAGRAPHS"),
            text_sentences=env_int("FAKER_TEXT_SENTENCES"),
            text_max_sentences=env_int("FAKER_TEXT_MAX_SENTENCES"),
            cache_entries=env_int("FAKER_CACHE_ENTRIES"),
        )
