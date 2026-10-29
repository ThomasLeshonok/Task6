import sys
from pathlib import Path

from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fakerdb.config import ROOT, Settings   
from fakerdb.database import Database   
from fakerdb.installer import install   
from fakerdb.repository import StoredProcedureFaker   

def main() -> None:
    load_dotenv(ROOT / ".env")
    settings = Settings.from_env()
    db = Database.from_settings(settings)
    try:
        files = install(db, settings.sql_dir)
        locales = StoredProcedureFaker(db).locales()
    finally:
        db.close()
    print(f"Applied {len(files)} SQL files from {settings.sql_dir}")
    print("Locales:", ", ".join(f"{loc.code} ({loc.name})" for loc in locales))

if __name__ == "__main__":
    main()
