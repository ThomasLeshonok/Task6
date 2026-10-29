import ssl
from typing import Any
from urllib.parse import parse_qs, unquote, urlparse

from pymysql.cursors import DictCursor

from .config import Settings

MYSQL_SCHEMES = {"mysql", "mysql+pymysql", "mariadb"}
SSL_MODE_PARAM = "ssl-mode"
SSL_DISABLED = "DISABLED"
SSL_REQUIRED = "REQUIRED"
SSL_VERIFY_IDENTITY = "VERIFY_IDENTITY"
PEM_MARKER = "-----BEGIN"

def ssl_context(mode: str, ca: str) -> ssl.SSLContext | None:
    mode = mode.upper()
    if mode in ("", SSL_DISABLED):
        return None
    if ca.lstrip().startswith(PEM_MARKER):
        context = ssl.create_default_context(cadata=ca)
    else:
        context = ssl.create_default_context(cafile=ca or None)
    context.verify_flags &= ~ssl.VERIFY_X509_STRICT
    context.check_hostname = mode == SSL_VERIFY_IDENTITY
    if mode == SSL_REQUIRED:
        context.verify_mode = ssl.CERT_NONE
    return context

def connection_args(settings: Settings) -> dict[str, Any]:
    if not settings.database_url:
        raise ValueError("DATABASE_URL is not set")
    url = urlparse(settings.database_url)
    if url.scheme not in MYSQL_SCHEMES:
        raise ValueError("DATABASE_URL must look like mysql://user:password@host:3306/database")
    query = {name.lower(): values[-1] for name, values in parse_qs(url.query).items()}
    args = {
        "host": url.hostname,
        "port": url.port or settings.db_default_port,
        "user": unquote(url.username or ""),
        "password": unquote(url.password or ""),
        "database": unquote(url.path.lstrip("/")),
        "charset": settings.db_charset,
        "autocommit": True,
        "cursorclass": DictCursor,
        "connect_timeout": settings.db_connect_timeout,
    }
    context = ssl_context(settings.db_ssl_mode or query.get(SSL_MODE_PARAM, SSL_DISABLED), settings.db_ssl_ca)
    if context:
        args["ssl"] = context
    return args
