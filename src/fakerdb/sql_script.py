DEFAULT_DELIMITER = ";"
DELIMITER_COMMAND = "DELIMITER"
COMMENT_PREFIX = "--"

def split_statements(script: str) -> list[str]:
    statements: list[str] = []
    buffer: list[str] = []
    delimiter = DEFAULT_DELIMITER
    for line in script.splitlines():
        stripped = line.strip()
        if not buffer and stripped.upper().startswith(DELIMITER_COMMAND + " "):
            delimiter = stripped.split(None, 1)[1].strip()
            continue
        if stripped.startswith(COMMENT_PREFIX) or (not buffer and not stripped):
            continue
        buffer.append(line)
        if stripped.endswith(delimiter):
            buffer[-1] = line.rstrip()[: -len(delimiter)]
            statement = "\n".join(buffer).strip()
            if statement:
                statements.append(statement)
            buffer = []
    if any(part.strip() for part in buffer):
        raise ValueError(f"SQL script ends inside a statement (missing {delimiter!r})")
    return statements
