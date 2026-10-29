import ssl
from pathlib import Path

import pytest

from fakerdb.config import DEFAULTS, Settings
from fakerdb.connection import connection_args, ssl_context
from fakerdb.database import ConnectionPool
from fakerdb.installer import install, sql_files
from fakerdb.models import BatchRequest, FakeUser, Locale, TextRequest
from fakerdb.repository import USERS_SQL, StoredProcedureFaker
from fakerdb.sql_script import split_statements
from webapp import state

class FakeRunner:
    def __init__(self, rows):
        self.rows = rows
        self.calls = []

    def fetch(self, sql, params):
        self.calls.append((sql, params))
        return self.rows

class RecordingScripts:
    def __init__(self):
        self.statements = []

    def run_statements(self, statements):
        self.statements.extend(statements)

def user_row(position=1):
    return {name: position if name == "position" else name for name in FakeUser.__dataclass_fields__}

def test_settings_defaults_and_overrides(monkeypatch):
    monkeypatch.delenv("FAKER_BATCH_SIZE", raising=False)
    assert Settings.from_env().batch_size == DEFAULTS["FAKER_BATCH_SIZE"]
    monkeypatch.setenv("FAKER_BATCH_SIZE", "25")
    assert Settings.from_env().batch_size == 25

def test_repository_maps_rows_and_passes_arguments():
    runner = FakeRunner([user_row(11), user_row(12)])
    request = BatchRequest("en_US", 7, 1, 10, 2)
    users = StoredProcedureFaker(runner).users(request)
    assert [u.position for u in users] == [11, 12]
    assert runner.calls == [(USERS_SQL, {"locale": "en_US", "seed": 7, "batch": 1, "batch_size": 10,
                                         "about_sentences": 2})]

def test_repository_locales_and_text():
    assert StoredProcedureFaker(FakeRunner([{"code": "de_DE", "name": "Deutsch"}])).locales() == [
        Locale("de_DE", "Deutsch")]
    assert StoredProcedureFaker(FakeRunner([{"paragraph": "Hallo."}])).text(TextRequest("de_DE", 1, 1, 1)) == [
        "Hallo."]

def test_sql_files_order(settings):
    files = sql_files(settings.sql_dir)
    parts = [f.relative_to(settings.sql_dir).parts for f in files]
    first_locale = next(i for i, p in enumerate(parts) if p[0] == "locales")
    assert all(p[0] == "schema" for p in parts[:first_locale])
    assert all(p[0] == "locales" for p in parts[first_locale:])
    assert parts[0] == ("schema", "01_tables.sql")

def test_install_sends_statements_in_order(settings):
    runner = RecordingScripts()
    install(runner, settings.sql_dir)
    assert runner.statements[0].startswith("SET SESSION sql_mode")
    assert any(s.startswith("CREATE PROCEDURE faker_generate_users(") for s in runner.statements)
    assert any(s.startswith("CALL faker_train_markov(") for s in runner.statements)
    assert runner.statements[-1].startswith("CALL faker_add_geo_region(")

def test_split_statements_handles_delimiter():
    script = """-- comment;
SET NAMES utf8mb4;
DELIMITER $$
CREATE PROCEDURE p()
BEGIN
    SELECT 1;
END$$
DELIMITER ;
CALL p();
"""
    assert split_statements(script) == [
        "SET NAMES utf8mb4", "CREATE PROCEDURE p()\nBEGIN\n    SELECT 1;\nEND", "CALL p()"]

def test_split_statements_rejects_unterminated():
    with pytest.raises(ValueError):
        split_statements("SELECT 1")

def test_connection_args_from_url(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "mysql://avn%40admin:p%3Ass@db.example.com:12345/faker?ssl-mode=REQUIRED")
    monkeypatch.delenv("DB_SSL_MODE", raising=False)
    args = connection_args(Settings.from_env())
    assert (args["host"], args["port"], args["user"], args["password"], args["database"]) == (
        "db.example.com", 12345, "avn@admin", "p:ss", "faker")
    assert args["ssl"] is not None and not args["ssl"].check_hostname

def test_connection_args_rejects_other_databases(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://u@h/db")
    with pytest.raises(ValueError):
        connection_args(Settings.from_env())

def test_ssl_modes():
    assert ssl_context("DISABLED", "") is None and ssl_context("", "") is None
    assert ssl_context("VERIFY_IDENTITY", "").check_hostname
    verify_ca = ssl_context("VERIFY_CA", "")
    assert not verify_ca.check_hostname and verify_ca.verify_mode == ssl.CERT_REQUIRED
    assert not verify_ca.verify_flags & ssl.VERIFY_X509_STRICT  # MySQL server certificates often lack AKI

class FakeConnection:
    def __init__(self):
        self.open = True
        self.pings = 0

    def ping(self, reconnect):
        self.pings += 1

    def close(self):
        self.open = False

def test_pool_reuses_and_pings_only_idle_connections():
    now = [0.0]
    made = []
    pool = ConnectionPool(lambda: made.append(FakeConnection()) or made[-1], size=2, ping_after=30, clock=lambda: now[0])
    with pool.connection() as first:
        pass
    with pool.connection() as again:
        assert again is first and first.pings == 0
    now[0] = 31
    with pool.connection():
        assert first.pings == 1
    with pytest.raises(RuntimeError):
        with pool.connection():
            raise RuntimeError("query failed")
    assert not first.open
    with pool.connection() as fresh:
        assert fresh is not first and len(made) == 2

def test_install_rejects_empty_folder(tmp_path: Path):
    with pytest.raises(FileNotFoundError):
        install(RecordingScripts(), tmp_path)

def test_navigation():
    session = {}
    state.init_state(session, "en_US", 42)
    assert state.current(session) == state.Selection("en_US", 42, 0)
    state.previous_batch(session)
    assert state.current(session).batch == 0
    state.next_batch(session)
    state.next_batch(session)
    assert state.current(session).batch == 2
    state.randomize_seed(session, 100, draw=lambda limit: limit - 1)
    assert state.current(session) == state.Selection("en_US", 100, 0)
