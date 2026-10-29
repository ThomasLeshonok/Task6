from dataclasses import asdict

from .models import BatchRequest, FakeUser, Locale, TextRequest
from .ports import QueryRunner

LOCALES_SQL = "CALL faker_list_locales()"
USERS_SQL = "CALL faker_generate_users(%(locale)s, %(seed)s, %(batch)s, %(batch_size)s, %(about_sentences)s)"
TEXT_SQL = "CALL faker_generate_text(%(locale)s, %(seed)s, %(paragraphs)s, %(sentences)s)"

class StoredProcedureFaker:
    def __init__(self, runner: QueryRunner):
        self._runner = runner

    def locales(self) -> list[Locale]:
        return [Locale(**row) for row in self._runner.fetch(LOCALES_SQL, {})]

    def users(self, request: BatchRequest) -> list[FakeUser]:
        return [FakeUser(**row) for row in self._runner.fetch(USERS_SQL, asdict(request))]

    def text(self, request: TextRequest) -> list[str]:
        return [row["paragraph"] for row in self._runner.fetch(TEXT_SQL, asdict(request))]
