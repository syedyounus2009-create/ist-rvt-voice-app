"""
IST-RVT Auth Router — JWT-based authentication
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
import bcrypt
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import get_db
from models.user import User

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()


# ── Schemas ──────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    display_name: Optional[str] = None
    phone: Optional[str] = None
    preferred_language: str = "en"
    target_language: str = "ar"


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    username: str
    display_name: Optional[str]
    preferred_language: str
    target_language: str


class UserProfile(BaseModel):
    id: str
    username: str
    email: str
    display_name: Optional[str]
    phone: Optional[str]
    preferred_language: str
    target_language: str
    is_online: bool
    total_calls: int
    total_translations: int
    created_at: datetime


# ── Helpers ──────────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    # Truncate string to 72 bytes max (bcrypt limit)
    pwd_bytes = password[:72].encode('utf-8')
    return bcrypt.hashpw(pwd_bytes, bcrypt.gensalt()).decode('utf-8')


def verify_password(plain: str, hashed: str) -> bool:
    # Truncate input to 72 bytes max to match
    return bcrypt.checkpw(plain[:72].encode('utf-8'), hashed.encode('utf-8'))


def create_access_token(user_id: str, username: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    data = {"sub": user_id, "username": username, "exp": expire}
    return jwt.encode(data, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token expired or invalid")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    return user


# ── Routes ───────────────────────────────────────────────────────────────────

@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check existing user
    result = await db.execute(
        select(User).where(
            (User.username == data.username) | (User.email == data.email)
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username or email already exists")

    user = User(
        id=str(uuid.uuid4()),
        username=data.username,
        email=data.email,
        hashed_password=hash_password(data.password),
        display_name=data.display_name or data.username,
        phone=data.phone,
        preferred_language=data.preferred_language,
        target_language=data.target_language,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(user.id, user.username)
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        username=user.username,
        display_name=user.display_name,
        preferred_language=user.preferred_language,
        target_language=user.target_language,
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == data.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    # Mark online
    user.is_online = True
    await db.commit()

    token = create_access_token(user.id, user.username)
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        username=user.username,
        display_name=user.display_name,
        preferred_language=user.preferred_language,
        target_language=user.target_language,
    )


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserProfile(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        display_name=current_user.display_name,
        phone=current_user.phone,
        preferred_language=current_user.preferred_language,
        target_language=current_user.target_language,
        is_online=current_user.is_online,
        total_calls=current_user.total_calls,
        total_translations=current_user.total_translations,
        created_at=current_user.created_at,
    )


@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.is_online = False
    await db.commit()
    return {"message": "Logged out successfully"}


@router.put("/profile")
async def update_profile(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    allowed = ["display_name", "preferred_language", "target_language", "phone"]
    for key in allowed:
        if key in data:
            setattr(current_user, key, data[key])
    await db.commit()
    return {"message": "Profile updated"}