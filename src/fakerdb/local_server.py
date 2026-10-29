"""Throwaway MySQL / MariaDB server: a new data directory, started on a free local port, deleted when done.

Benchmarks run against it so they neither touch the database in DATABASE_URL nor depend on how it is tuned.
Tested with the MariaDB 10.4 of XAMPP on Windows; MySQL 8 is initialized with --initialize-insecure instead.
"""
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pymysql

HOST = "127.0.0.1"
USER = "root"
DATABASE = "faker"
SERVER_NAMES = ("mariadbd", "mysqld")
INSTALLER_NAMES = ("mariadb-install-db", "mysql_install_db")
FALLBACK_DIRS = (Path(r"C:\xampp\mysql\bin"),)
START_TIMEOUT = 60.0
STOP_TIMEOUT = 60.0
POLL_SECONDS = 0.25
CONNECT_TIMEOUT = 5
LOG_TAIL_CHARS = 2_000

def free_port() -> int:
    """A TCP port nothing listens on right now (chosen by the operating system)."""
    with socket.socket() as sock:
        sock.bind((HOST, 0))
        return sock.getsockname()[1]

def which(names: tuple[str, ...], path: str | None = None) -> Path | None:
    for name in names:
        found = shutil.which(name, path=path)
        if found:
            return Path(found)
    return None

def find_server(explicit: str | None = None) -> Path:
    """The server binary: the given path, else mariadbd / mysqld on PATH, else XAMPP's."""
    if explicit:
        server = Path(explicit)
        if not server.is_file():
            raise FileNotFoundError(f"No database server at {server}")
        return server
    server = which(SERVER_NAMES) or which(SERVER_NAMES, os.pathsep.join(map(str, FALLBACK_DIRS)))
    if server is None:
        raise FileNotFoundError("No mariadbd or mysqld on PATH or in C:\\xampp\\mysql\\bin; pass its path")
    return server

def run(command: list[str]) -> str:
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"{' '.join(command)} failed ({result.returncode}):\n{result.stdout}{result.stderr}")
    return result.stdout

class LocalServer:
    """Context manager: initializes a data directory, starts the server on a free port and creates the database
    DATABASE (user root, no password); on exit shuts the server down and deletes the directory."""

    def __init__(self, server: Path, port: int | None = None):
        self.server = server
        self.port = port or free_port()
        self.version = ""
        self._workdir: tempfile.TemporaryDirectory | None = None
        self._dir = Path()
        self._process: subprocess.Popen | None = None

    @property
    def url(self) -> str:
        return f"mysql://{USER}@{HOST}:{self.port}/{DATABASE}"

    def __enter__(self) -> "LocalServer":
        self._workdir = tempfile.TemporaryDirectory(prefix="faker-server-", ignore_cleanup_errors=True)
        self._dir = Path(self._workdir.name)
        try:
            self.version = run([str(self.server), "--version"]).strip()
            self._initialize()
            self._start()
            with self._connect() as conn, conn.cursor() as cursor:
                cursor.execute(f"CREATE DATABASE {DATABASE} CHARACTER SET utf8mb4")
        except BaseException:
            self.__exit__()
            raise
        return self

    def __exit__(self, *_: object) -> None:
        if self._process and self._process.poll() is None:
            try:
                with self._connect() as conn, conn.cursor() as cursor:
                    cursor.execute("SHUTDOWN")
            except pymysql.MySQLError:
                self._process.terminate()
            try:
                self._process.wait(STOP_TIMEOUT)
            except subprocess.TimeoutExpired:
                self._process.kill()
                self._process.wait()
        if self._workdir:
            self._workdir.cleanup()

    def _initialize(self) -> None:
        data = self._dir / "data"
        if "MariaDB" not in self.version:
            run([str(self.server), "--no-defaults", "--initialize-insecure", f"--datadir={data}"])
            return
        installer = which(INSTALLER_NAMES, str(self.server.parent)) or which(INSTALLER_NAMES)
        if installer is None:
            raise FileNotFoundError(f"No mariadb-install-db or mysql_install_db next to {self.server} or on PATH")
        if sys.platform == "win32":
            run([str(installer), f"--datadir={data}", "--silent"])
        else:
            run([str(installer), "--no-defaults", f"--datadir={data}", f"--basedir={self.server.parent.parent}",
                 "--auth-root-authentication-method=normal"])

    def _start(self) -> None:
        # Windows takes a named pipe name as socket, other systems a file; a unique one avoids clashing with a
        # server that is already running. MySQL 8's X plugin would also listen on 33060 (MariaDB has none: loose-).
        socket_name = f"faker-server-{self.port}" if sys.platform == "win32" else str(self._dir / "server.sock")
        log = self._dir / "error.log"
        command = [str(self.server), "--no-defaults", f"--datadir={self._dir / 'data'}", f"--port={self.port}",
                   f"--bind-address={HOST}", f"--socket={socket_name}", f"--pid-file={self._dir / 'server.pid'}",
                   f"--log-error={log}", "--character-set-server=utf8mb4", "--loose-mysqlx=OFF"]
        self._process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + START_TIMEOUT
        while True:
            try:
                self._connect().close()
                return
            except pymysql.err.OperationalError:
                if self._process.poll() is not None:
                    tail = log.read_text(errors="replace")[-LOG_TAIL_CHARS:] if log.exists() else ""
                    raise RuntimeError(f"{self.server} exited with code {self._process.returncode}:\n{tail}")
                if time.monotonic() > deadline:
                    raise RuntimeError(f"{self.server} did not accept connections within {START_TIMEOUT:.0f} s")
                time.sleep(POLL_SECONDS)

    def _connect(self) -> pymysql.Connection:
        return pymysql.connect(host=HOST, port=self.port, user=USER, password="", autocommit=True,
                               connect_timeout=CONNECT_TIMEOUT)
