from datetime import UTC, datetime


def utcnow() -> datetime:
    """Naive UTC timestamp, kept tzinfo-free to match SQLite's timezone-naive DATETIME storage."""
    return datetime.now(UTC).replace(tzinfo=None)
