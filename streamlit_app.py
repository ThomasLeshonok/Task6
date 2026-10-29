import sys
from pathlib import Path

import pymysql
import streamlit as st
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "src"))
load_dotenv(ROOT / ".env")
st.secrets.load_if_toml_exists()  

from fakerdb.config import Settings   
from fakerdb.database import Database   
from fakerdb.models import BatchRequest, FakeUser, Locale, TextRequest   
from fakerdb.repository import StoredProcedureFaker   
from webapp import views   
from webapp.controls import sidebar   

SETTINGS = Settings.from_env()

st.set_page_config(page_title="Fake User Generator", page_icon=":material/badge:", layout="wide")

@st.cache_resource(show_spinner="Connecting to the database...")
def get_faker() -> StoredProcedureFaker:
    return StoredProcedureFaker(Database.from_settings(SETTINGS))

@st.cache_data(max_entries=SETTINGS.cache_entries)
def get_locales() -> list[Locale]:
    return get_faker().locales()

@st.cache_data(show_spinner="Generating users...", max_entries=SETTINGS.cache_entries)
def get_users(request: BatchRequest) -> list[FakeUser]:
    return get_faker().users(request)

@st.cache_data(show_spinner="Generating text...", max_entries=SETTINGS.cache_entries)
def get_text(request: TextRequest) -> list[str]:
    return get_faker().text(request)

def load_locales() -> list[Locale]:
    try:
        locales = get_locales()
    except (ValueError, pymysql.MySQLError) as error:
        st.error(f"Database is not ready: {error}")
        st.info("Set `DATABASE_URL` in `.env` and run `python src/setup_db.py`.")
        st.stop()
    if not locales:
        st.error("No locales in the database. Run `python src/setup_db.py`.")
        st.stop()
    return locales

def main() -> None:
    st.title("Fake User Generator")
    st.caption("Random but reproducible contact data, generated entirely by MySQL stored procedures.")
    selection = sidebar(load_locales(), SETTINGS.default_seed, SETTINGS.max_seed)
    users, text = st.tabs(["Users", "Random text"])
    with users:
        views.users_tab(get_users, selection, SETTINGS)
    with text:
        views.text_tab(get_text, selection, SETTINGS)

main()
