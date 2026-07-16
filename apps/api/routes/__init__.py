"""Route package — re-exports all routers for easy main.py import."""

from apps.api.routes import auth, parent, children, lessons
from apps.api.routes import games, progress, rewards, sync, admin

__all__ = ["auth", "parent", "children", "lessons", "games", "progress", "rewards", "sync", "admin"]
