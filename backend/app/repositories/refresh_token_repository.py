from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken


def create(db: Session, *, jti: str, user_id: str, expires_at: datetime) -> RefreshToken:
    token = RefreshToken(jti=jti, user_id=user_id, expires_at=expires_at)
    db.add(token)
    db.commit()
    db.refresh(token)
    return token


def get_by_jti(db: Session, jti: str) -> RefreshToken | None:
    return db.execute(select(RefreshToken).where(RefreshToken.jti == jti)).scalar_one_or_none()


def revoke(db: Session, token: RefreshToken) -> None:
    token.revoked = True
    db.add(token)
    db.commit()
