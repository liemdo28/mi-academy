"""Database configuration and session management."""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from apps.api.config import settings

# Async engine — works with SQLite (aiosqlite) and PostgreSQL (asyncpg).
# Pool sizing only applies to Postgres: SQLite's aiosqlite driver doesn't
# accept pool_size/max_overflow (it uses NullPool/StaticPool depending on
# the URL), and dev/tests run on SQLite. Without explicit sizing here,
# Postgres in production silently falls back to SQLAlchemy's defaults
# (pool_size=5, max_overflow=10 -- a ~15-connection ceiling per API
# process that's easy to exhaust under concurrent load without anyone
# having decided that's the right number).
_is_sqlite = settings.DATABASE_URL.startswith("sqlite")
_pool_kwargs = {} if _is_sqlite else {
    "pool_size": settings.DB_POOL_SIZE,
    "max_overflow": settings.DB_MAX_OVERFLOW,
}

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
    **_pool_kwargs,
)

# Session factory
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass


async def get_db() -> AsyncSession:
    """Dependency — yields a DB session per request."""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
