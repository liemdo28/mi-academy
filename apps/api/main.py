"""MI Academy API — FastAPI application entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from apps.api.config import settings
from apps.api.database import engine, Base
from apps.api.middleware.rate_limit import RateLimitMiddleware
from apps.api.routes import (
    auth,
    parent,
    children,
    lessons,
    games,
    progress,
    rewards,
    sync,
    admin,
)

app = FastAPI(
    title="MI Academy API",
    version="1.0.0",
    description="Backend API for MI Academy — Offline-first educational games for children 5–12",
)

# CORS — allow mobile app + web dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting
app.add_middleware(
    RateLimitMiddleware,
    auth_limit=settings.AUTH_RATE_LIMIT_PER_MIN,
    sync_limit=settings.SYNC_RATE_LIMIT_PER_MIN,
)

# Register routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(parent.router, prefix="/api/v1/parent", tags=["parent"])
app.include_router(children.router, prefix="/api/v1/children", tags=["children"])
app.include_router(lessons.router, prefix="/api/v1/lessons", tags=["lessons"])
app.include_router(games.router, prefix="/api/v1/games", tags=["games"])
app.include_router(progress.router, prefix="/api/v1/progress", tags=["progress"])
app.include_router(rewards.router, prefix="/api/v1/rewards", tags=["rewards"])
app.include_router(sync.router, prefix="/api/v1/sync", tags=["sync"])
app.include_router(admin.router, prefix="/admin/api/v1", tags=["admin"])


@app.get("/api/v1/health")
async def health_check():
    return {"status": "ok", "version": "1.0.0"}


@app.on_event("startup")
async def startup():
    # Create tables — use only in dev; migrations handle prod
    if settings.CREATE_TABLES_ON_STARTUP:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
