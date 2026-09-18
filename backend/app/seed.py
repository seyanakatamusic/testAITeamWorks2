from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.user import UserRole
from app.repositories import user_repository

SEED_ADMIN_EMAIL = "admin@example.com"
SEED_ADMIN_PASSWORD = "dev-admin-pass-123"
SEED_EMPLOYEE_EMAIL = "employee@example.com"
SEED_EMPLOYEE_PASSWORD = "dev-employee-pass-123"


def seed_dev_users(db: Session) -> None:
    if user_repository.get_by_email(db, SEED_ADMIN_EMAIL) is None:
        user_repository.create_user(
            db,
            name="Dev Admin",
            email=SEED_ADMIN_EMAIL,
            password_hash=hash_password(SEED_ADMIN_PASSWORD),
            role=UserRole.admin,
        )

    if user_repository.get_by_email(db, SEED_EMPLOYEE_EMAIL) is None:
        user_repository.create_user(
            db,
            name="Dev Employee",
            email=SEED_EMPLOYEE_EMAIL,
            password_hash=hash_password(SEED_EMPLOYEE_PASSWORD),
            role=UserRole.employee,
        )
