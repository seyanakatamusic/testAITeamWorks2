import uuid
from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import (
    REFRESH_TOKEN_TYPE,
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)
from app.core.time import utcnow
from app.models.user import User
from app.repositories import refresh_token_repository, user_repository
from app.schemas.auth import TokenResponse

settings = get_settings()

_invalid_credentials_error = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED, detail="メールアドレスまたはパスワードが正しくありません"
)
_invalid_refresh_error = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED, detail="リフレッシュトークンが無効です"
)


def _issue_tokens(db: Session, user: User) -> TokenResponse:
    access_jti = str(uuid.uuid4())
    refresh_jti = str(uuid.uuid4())

    access_token = create_access_token(user_id=user.id, role=user.role, jti=access_jti)
    refresh_token = create_refresh_token(user_id=user.id, role=user.role, jti=refresh_jti)

    refresh_token_repository.create(
        db,
        jti=refresh_jti,
        user_id=user.id,
        expires_at=utcnow() + timedelta(minutes=settings.refresh_token_expire_minutes),
    )

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


def authenticate_user(db: Session, *, email: str, password: str) -> User:
    user = user_repository.get_by_email(db, email)
    if user is None or not user.is_active or not verify_password(password, user.password_hash):
        raise _invalid_credentials_error
    return user


def login(db: Session, *, email: str, password: str) -> TokenResponse:
    user = authenticate_user(db, email=email, password=password)
    return _issue_tokens(db, user)


def _get_valid_refresh_token(db: Session, refresh_token: str):
    payload = decode_token(refresh_token)
    if payload.get("type") != REFRESH_TOKEN_TYPE:
        raise _invalid_refresh_error

    jti = payload.get("jti")
    stored = refresh_token_repository.get_by_jti(db, jti) if jti else None
    if stored is None or stored.revoked or stored.expires_at < utcnow():
        raise _invalid_refresh_error

    return stored, payload


def refresh(db: Session, *, refresh_token: str) -> TokenResponse:
    stored, payload = _get_valid_refresh_token(db, refresh_token)
    user = user_repository.get_by_id(db, payload["sub"])
    if user is None or not user.is_active:
        raise _invalid_refresh_error

    refresh_token_repository.revoke(db, stored)
    return _issue_tokens(db, user)


def logout(db: Session, *, refresh_token: str) -> None:
    stored, _ = _get_valid_refresh_token(db, refresh_token)
    refresh_token_repository.revoke(db, stored)
