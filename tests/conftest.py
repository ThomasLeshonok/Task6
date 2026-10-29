import sys
from pathlib import Path

import pytest
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
load_dotenv(ROOT / ".env")

from fakerdb.config import Settings  # noqa: E402
from fakerdb.database import Database  # noqa: E402

@pytest.fixture(scope="session")
def settings() -> Settings:
    return Settings.from_env()

@pytest.fixture(scope="session")
def db(settings):
    """Database with the faker schema installed; tests using it are skipped without a reachable DATABASE_URL."""
    if not settings.database_url:
        pytest.skip("DATABASE_URL is not set")
    try:
        database = Database.from_settings(settings)
        database.fetch("CALL faker_list_locales()", {})
    except Exception as error:  # noqa: BLE001 - any connection or schema problem means "not available"
        pytest.skip(f"faker database not available: {error}")
    yield database
    database.close()

@pytest.fixture(scope="session")
def faker(db):
    from fakerdb.repository import StoredProcedureFaker
    return StoredProcedureFaker(db)
