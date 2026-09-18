import os
from collections.abc import Iterator

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.security import hash_password
from app.main import app
from app.models.user import UserRole
from app.repositories import user_repository


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    testing_session_local = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = testing_session_local()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(db_session) -> Iterator[TestClient]:
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def admin_user(db_session):
    return user_repository.create_user(
        db_session,
        name="Admin User",
        email="admin@example.com",
        password_hash=hash_password("correct-password"),
        role=UserRole.admin,
    )


@pytest.fixture()
def employee_user(db_session):
    return user_repository.create_user(
        db_session,
        name="Employee User",
        email="employee@example.com",
        password_hash=hash_password("correct-password"),
        role=UserRole.employee,
    )
