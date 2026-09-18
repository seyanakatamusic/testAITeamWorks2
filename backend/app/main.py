from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.database import Base, SessionLocal, engine
from app.models import refresh_token, user  # noqa: F401 (register models on Base.metadata)
from app.routers.auth import router as auth_router
from app.seed import seed_dev_users


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_dev_users(db)
    finally:
        db.close()
    yield


app = FastAPI(title="Attendance SaaS API", lifespan=lifespan)
app.include_router(auth_router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
