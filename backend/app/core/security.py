from datetime import timedelta
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.time import utcnow
from app.models.user import User, UserRole
from app.repositories import user_repository

settings = get_settings()
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
_bearer_scheme = HTTPBearer(auto_error=False)

ACCESS_TOKEN_TYPE = "access"
REFRESH_TOKEN_TYPE = "refresh"


def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain_password: str, password_hash: str) -> bool:
    return _pwd_context.verify(plain_password, password_hash)


def _create_token(
    *, subject: str, role: UserRole, token_type: str, expires_delta: timedelta, jti: str
) -> str:
    now = utcnow()
    payload: dict[str, Any] = {
        "sub": subject,
        "role": role.value,
        "type": token_type,
        "jti": jti,
        "iat": now,
        "exp": now + expires_delta,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_access_token(*, user_id: str, role: UserRole, jti: str) -> str:
    return _create_token(
        subject=user_id,
        role=role,
        token_type=ACCESS_TOKEN_TYPE,
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
        jti=jti,
    )


def create_refresh_token(*, user_id: str, role: UserRole, jti: str) -> str:
    return _create_token(
        subject=user_id,
        role=role,
        token_type=REFRESH_TOKEN_TYPE,
        expires_delta=timedelta(minutes=settings.refresh_token_expire_minutes),
        jti=jti,
    )


def decode_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="トークンが無効です") from exc


_credentials_error = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="認証情報が無効です")


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise _credentials_error

    payload = decode_token(credentials.credentials)
    if payload.get("type") != ACCESS_TOKEN_TYPE:
        raise _credentials_error

    user_id = payload.get("sub")
    if not user_id:
        raise _credentials_error

    user = user_repository.get_by_id(db, user_id)
    if user is None or not user.is_active:
        raise _credentials_error

    return user


def require_role(*allowed_roles: UserRole):
    def _dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="この操作を行う権限がありません"
            )
        return current_user

    return _dependency
