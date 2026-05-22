"""
IST-RVT Contacts Router
"""

import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.user import User
from routers.auth import get_current_user

router = APIRouter(prefix="/contacts", tags=["Contacts"])


class ContactInfo(BaseModel):
    id: str
    username: str
    display_name: Optional[str]
    preferred_language: str
    is_online: bool
    total_calls: int


@router.get("/search")
async def search_users(
    query: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Search users by username or display name."""
    result = await db.execute(
        select(User).where(
            (User.username.ilike(f"%{query}%") | User.display_name.ilike(f"%{query}%"))
            & (User.id != current_user.id)
            & (User.is_active == True)
        ).limit(20)
    )
    users = result.scalars().all()
    return [
        ContactInfo(
            id=u.id,
            username=u.username,
            display_name=u.display_name,
            preferred_language=u.preferred_language,
            is_online=u.is_online,
            total_calls=u.total_calls,
        )
        for u in users
    ]


@router.get("/online")
async def online_users(current_user: User = Depends(get_current_user)):
    """Get list of currently online users."""
    from services.room_manager import room_manager
    return {"online_users": room_manager.online_users()}


@router.get("/{user_id}", response_model=ContactInfo)
async def get_user(
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "User not found")
    return ContactInfo(
        id=user.id,
        username=user.username,
        display_name=user.display_name,
        preferred_language=user.preferred_language,
        is_online=user.is_online,
        total_calls=user.total_calls,
    )
