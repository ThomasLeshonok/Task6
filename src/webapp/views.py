from collections.abc import Callable
from dataclasses import asdict

import pandas as pd
import streamlit as st

from fakerdb.config import Settings
from fakerdb.models import BatchRequest, FakeUser, TextRequest

from . import state

COORDINATE_DECIMALS = 5
COORDINATE_FORMAT = f"%.{COORDINATE_DECIMALS}f"
TABLE_KEY = "users_table"

USER_COLUMNS = {
    "position": st.column_config.NumberColumn("#", width="small"),
    "full_name": st.column_config.TextColumn("Name"),
    "gender": st.column_config.TextColumn("Gender", width="small"),
    "address": st.column_config.TextColumn("Address", width="large"),
    "phone": st.column_config.TextColumn("Phone"),
    "email": st.column_config.TextColumn("E-mail"),
    "height": st.column_config.TextColumn("Height", width="small"),
    "weight": st.column_config.TextColumn("Weight", width="small"),
    "eye_color": st.column_config.TextColumn("Eyes", width="small"),
    "hair_color": st.column_config.TextColumn("Hair", width="small"),
    "blood_type": st.column_config.TextColumn("Blood", width="small"),
    "latitude": st.column_config.NumberColumn("Latitude", format=COORDINATE_FORMAT),
    "longitude": st.column_config.NumberColumn("Longitude", format=COORDINATE_FORMAT),
    "about": st.column_config.TextColumn("About (Markov text)", width="large"),
}

def batch_navigation(selection: state.Selection, batch_size: int) -> None:
    first = selection.batch * batch_size + 1
    session = st.session_state
    with st.container(horizontal=True, vertical_alignment="center"):
        st.button("Previous", icon=":material/arrow_back:", on_click=state.previous_batch, args=(session,),
                  disabled=selection.batch == 0)
        st.markdown(f"**Batch {selection.batch + 1:,}** · users {first:,}–{first + batch_size - 1:,}")
        st.button("Next batch", icon=":material/arrow_forward:", type="primary", on_click=state.next_batch,
                  args=(session,))

def user_card(user: FakeUser) -> None:
    with st.container(border=True):
        st.markdown(f"#### {user.full_name}")
        st.caption(f"#{user.position:,} · {user.gender}")
        left, right = st.columns(2)
        left.markdown(f":material/home: {user.address}  \n:material/call: {user.phone}  \n:material/mail: {user.email}")
        right.markdown(
            f":material/straighten: {user.height} ({user.height_cm:g} cm) · {user.weight} ({user.weight_kg:g} kg)  \n"
            f":material/visibility: {user.eye_color} · hair {user.hair_color} · blood {user.blood_type}  \n"
            f":material/location_on: {user.latitude:.{COORDINATE_DECIMALS}f}, {user.longitude:.{COORDINATE_DECIMALS}f}")
        st.markdown(f"*{user.about}*")

def users_table(users: list[FakeUser]) -> None:
    frame = pd.DataFrame([asdict(u) for u in users])
    event = st.dataframe(frame[list(USER_COLUMNS)], column_config=USER_COLUMNS, hide_index=True, width="stretch",
                         on_select="rerun", selection_mode="single-row", key=TABLE_KEY)
    rows = event.selection.rows
    if rows:
        user_card(users[rows[0]])
    else:
        st.caption("Select a row to see the full card.")
    with st.expander("Map of this batch"):
        st.map(frame, latitude="latitude", longitude="longitude")

def users_tab(fetch_users: Callable[[BatchRequest], list[FakeUser]], selection: state.Selection,
              settings: Settings) -> None:
    request = BatchRequest(selection.locale, selection.seed, selection.batch, settings.batch_size,
                           settings.about_sentences)
    batch_navigation(selection, settings.batch_size)
    users_table(fetch_users(request))

def text_tab(fetch_text: Callable[[TextRequest], list[str]], selection: state.Selection, settings: Settings) -> None:
    st.caption("Word-level Markov chain trained on a corpus in the locale language. Same locale and seed, same text.")
    with st.container(horizontal=True):
        paragraphs = st.number_input("Paragraphs", min_value=1, max_value=settings.text_max_paragraphs,
                                     value=settings.text_paragraphs)
        sentences = st.number_input("Sentences per paragraph", min_value=1, max_value=settings.text_max_sentences,
                                    value=settings.text_sentences)
    for paragraph in fetch_text(TextRequest(selection.locale, selection.seed, int(paragraphs), int(sentences))):
        st.write(paragraph)
