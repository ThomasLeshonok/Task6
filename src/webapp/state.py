import secrets
from collections.abc import Callable, MutableMapping
from dataclasses import dataclass

LOCALE_KEY = "locale"
SEED_KEY = "seed"
BATCH_KEY = "batch_no" 
FIRST_BATCH_NO = 1

@dataclass(frozen=True)
class Selection:
    locale: str
    seed: int
    batch: int 

def init_state(state: MutableMapping, locale: str, seed: int) -> None:
    state.setdefault(LOCALE_KEY, locale)
    state.setdefault(SEED_KEY, seed)
    state.setdefault(BATCH_KEY, FIRST_BATCH_NO)

def current(state: MutableMapping) -> Selection:
    return Selection(state[LOCALE_KEY], int(state[SEED_KEY]), int(state[BATCH_KEY]) - FIRST_BATCH_NO)

def reset_batch(state: MutableMapping) -> None:
    state[BATCH_KEY] = FIRST_BATCH_NO

def next_batch(state: MutableMapping) -> None:
    state[BATCH_KEY] = int(state[BATCH_KEY]) + 1

def previous_batch(state: MutableMapping) -> None:
    state[BATCH_KEY] = max(FIRST_BATCH_NO, int(state[BATCH_KEY]) - 1)

def randomize_seed(state: MutableMapping, max_seed: int, draw: Callable[[int], int] = secrets.randbelow) -> None:
    state[SEED_KEY] = draw(max_seed + 1)
    reset_batch(state)
