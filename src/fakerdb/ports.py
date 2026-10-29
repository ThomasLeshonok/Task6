from typing import Any, Protocol

from .models import BatchRequest, FakeUser, Locale, TextRequest

Row = dict[str, Any]

class QueryRunner(Protocol):
    def fetch(self, sql: str, params: dict[str, Any]) -> list[Row]: ...

class ScriptRunner(Protocol):
    def run_statements(self, statements: list[str]) -> None: ...

class LocaleSource(Protocol):
    def locales(self) -> list[Locale]: ...

class UserSource(Protocol):
    def users(self, request: BatchRequest) -> list[FakeUser]: ...

class TextSource(Protocol):
    def text(self, request: TextRequest) -> list[str]: ...
