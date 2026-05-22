"""
IST-RVT Database Setup — SQLAlchemy async with SQLite/PostgreSQL support
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from config import settings
import os

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {},
)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Create all tables on startup."""
    from models import user, message, session as sess  # noqa: F401
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("[OK] Database initialized")
