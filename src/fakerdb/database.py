import queue
import threading
import time
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from typing import Any

import pymysql

from .config import Settings
from .connection import connection_args
from .ports import Row

class ConnectionPool:
    def __init__(self, connect: Callable[[], pymysql.Connection], size: int, ping_after: float,
                 clock: Callable[[], float] = time.monotonic):
        self._connect = connect
        self._ping_after = ping_after
        self._clock = clock
        self._idle: queue.LifoQueue = queue.LifoQueue(maxsize=size)
        self._slots = threading.BoundedSemaphore(size)

    @contextmanager
    def connection(self) -> Iterator[pymysql.Connection]:
        with self._slots:
            conn = self._checkout()
            try:
                yield conn
            except BaseException:
                if conn.open:
                    conn.close()
                raise
            self._idle.put_nowait((conn, self._clock()))

    def _checkout(self) -> pymysql.Connection:
        try:
            conn, released_at = self._idle.get_nowait()
        except queue.Empty:
            return self._connect()
        if self._clock() - released_at >= self._ping_after:
            conn.ping(reconnect=True)
        return conn

    def close(self) -> None:
        while not self._idle.empty():
            self._idle.get_nowait()[0].close()

class Database:
    def __init__(self, pool: ConnectionPool):
        self._pool = pool

    @classmethod
    def from_settings(cls, settings: Settings) -> "Database":
        args = connection_args(settings)
        return cls(ConnectionPool(lambda: pymysql.connect(**args), settings.db_pool_size, settings.db_ping_after_seconds))

    def fetch(self, sql: str, params: dict[str, Any]) -> list[Row]:
        with self._pool.connection() as conn, conn.cursor() as cursor:
            cursor.execute(sql, params)
            rows = list(cursor.fetchall())
            while cursor.nextset():
                pass
            return rows

    def run_statements(self, statements: list[str]) -> None:
        with self._pool.connection() as conn, conn.cursor() as cursor:
            for statement in statements:
                cursor.execute(statement)
                while cursor.nextset():
                    pass

    def close(self) -> None:
        self._pool.close()
