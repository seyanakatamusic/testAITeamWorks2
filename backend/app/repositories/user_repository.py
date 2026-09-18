from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User, UserRole


def get_by_email(db: Session, email: str) -> User | None:
    return db.execute(select(User).where(User.email == email)).scalar_one_or_none()


def get_by_id(db: Session, user_id: str) -> User | None:
    return db.get(User, user_id)


def create_user(
    db: Session,
    *,
    name: str,
    email: str,
    password_hash: str,
    role: UserRole = UserRole.employee,
    is_active: bool = True,
) -> User:
    user = User(name=name, email=email, password_hash=password_hash, role=role, is_active=is_active)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
