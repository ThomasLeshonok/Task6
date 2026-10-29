"""Starts a real throwaway server (skipped when no mariadbd / mysqld is installed)."""
import socket

import pymysql
import pytest

from fakerdb.local_server import DATABASE, HOST, USER, LocalServer, find_server, free_port

def test_free_port_is_bindable():
    with socket.socket() as sock:
        sock.bind((HOST, free_port()))

def test_server_starts_on_its_port_and_is_removed():
    try:
        server = find_server()
    except FileNotFoundError as error:
        pytest.skip(str(error))
    with LocalServer(server) as local:
        assert local.url == f"mysql://{USER}@{HOST}:{local.port}/{DATABASE}"
        conn = pymysql.connect(host=HOST, port=local.port, user=USER, password="", database=DATABASE)
        with conn, conn.cursor() as cursor:
            cursor.execute("SELECT @@port, DATABASE()")
            assert cursor.fetchone() == (local.port, DATABASE)
        workdir = local._dir
    assert not workdir.exists()
    with pytest.raises(pymysql.err.OperationalError):
        pymysql.connect(host=HOST, port=local.port, user=USER, password="", connect_timeout=2)
