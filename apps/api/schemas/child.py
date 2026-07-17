"""Child profile schemas."""

from pydantic import BaseModel, Field


class CreateChildRequest(BaseModel):
    nickname: str = Field(..., min_length=1, max_length=50)
    birth_year: int | None = Field(None, ge=2010, le=2022)
    age_group: str = Field(..., pattern="^(junior|explorer|master)$")
    grade_level: str | None = Field(None, max_length=50)
    avatar_id: str = Field(default="avatar_01")
    preferred_language: str = Field(default="vi", pattern="^(vi|en)$")
    daily_time_limit: int | None = Field(None, ge=5, le=180)  # minutes


class UpdateChildRequest(BaseModel):
    nickname: str | None = Field(None, min_length=1, max_length=50)
    birth_year: int | None = Field(None, ge=2010, le=2022)
    age_group: str | None = Field(None, pattern="^(junior|explorer|master)$")
    grade_level: str | None = Field(None, max_length=50)
    avatar_id: str | None = None
    preferred_language: str | None = Field(None, pattern="^(vi|en)$")
    daily_time_limit: int | None = Field(None, ge=5, le=180)


class ChildResponse(BaseModel):
    id: str
    parent_id: str
    nickname: str
    birth_year: int | None
    age_group: str
    grade_level: str | None
    avatar_id: str
    preferred_language: str
    daily_time_limit: int | None
    created_at: str

    @classmethod
    def from_model(cls, model) -> "ChildResponse":
        return cls(
            id=model.id,
            parent_id=model.parent_id,
            nickname=model.nickname,
            birth_year=model.birth_year,
            age_group=model.age_group,
            grade_level=model.grade_level,
            avatar_id=model.avatar_id,
            preferred_language=model.preferred_language,
            daily_time_limit=model.daily_time_limit,
            created_at=model.created_at.isoformat(),
        )
