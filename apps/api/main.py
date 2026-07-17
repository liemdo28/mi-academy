"""MI Academy API — FastAPI application entry point."""

from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from apps.api.config import settings
from apps.api.database import engine, Base
from apps.api.logging_config import configure_logging
from apps.api.middleware.rate_limit import RateLimitMiddleware
from apps.api.middleware.request_context import RequestContextMiddleware
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

configure_logging()

APP_VERSION = "1.0.0"

app = FastAPI(
    title="MI Academy API",
    version=APP_VERSION,
    description="Backend API for MI Academy — Offline-first educational games for children 5–12",
)

# Correlation ID + structured request logging — added first so it wraps
# every other middleware and captures their effect on status/duration.
app.add_middleware(RequestContextMiddleware)

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
    redis_url=settings.REDIS_URL,
    app_env=settings.APP_ENV,
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
    """Deprecated alias for /health/live — kept for existing clients."""
    return {"status": "ok", "version": APP_VERSION}


@app.get("/health/live")
async def health_live():
    """Liveness — confirms the process is running. Never checks dependencies."""
    return {"status": "ok"}


@app.get("/health/ready")
async def health_ready():
    """Readiness — confirms the service can serve requests, including the database."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception:
        return Response(status_code=503, content='{"status":"not_ready"}', media_type="application/json")
    return {"status": "ready"}


@app.get("/version")
async def version():
    return {"version": APP_VERSION, "environment": settings.APP_ENV}


@app.on_event("startup")
async def startup():
    # Create tables — use only in dev; migrations handle prod
    if settings.CREATE_TABLES_ON_STARTUP:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
