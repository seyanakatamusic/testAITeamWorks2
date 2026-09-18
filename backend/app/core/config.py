import os
from functools import lru_cache


class Settings:
    jwt_secret: str = os.getenv("JWT_SECRET", "dev-only-insecure-secret-change-me")
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    refresh_token_expire_minutes: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", str(60 * 24 * 7)))
    database_url: str = os.getenv("DATABASE_URL", "sqlite:///./attendance.db")


@lru_cache
def get_settings() -> Settings:
    return Settings()
