"""Backend mirror of schemas/level.schema.json (WS3 versioned content schema).

Not currently wired to a live endpoint -- the six existing games ship their
content as bundled mobile assets (apps/mobile/assets/levels/*.json), not via
a backend content API. This model exists so admin publishing / a future
content-sync endpoint validates against the *same* rules the mobile
ContentLoader/ContentValidator and tools/content_schema_validator.py already
enforce, per the "mobile and backend validate the same content concepts"
requirement -- not a parallel, independently-drifting rule set.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator

AgeBand = Literal["junior", "explorer", "master"]
PublicationState = Literal["draft", "published", "archived"]


class ContentOption(BaseModel):
    id: str
    text: str
    correct: bool | None = None
    media: str | None = None


class LocalizedLevelContent(BaseModel):
    prompt: str = Field(..., min_length=1)
    options: list[ContentOption | str] | None = None
    correctAnswer: str | None = None
    cards: list[dict] | None = None

    model_config = {"extra": "allow"}


class ContentHint(BaseModel):
    text: str = Field(..., min_length=1)
    media: str | None = None
    highlight: str | None = None
    action: dict | None = None


class ContentItem(BaseModel):
    """Mirrors schemas/level.schema.json's envelope."""

    id: str = Field(..., min_length=1)
    gameId: str = Field(..., min_length=1)
    levelNumber: int = Field(..., ge=1)
    difficulty: int = Field(..., ge=1, le=5)
    learningObjective: str | None = None
    localizedContent: dict[str, LocalizedLevelContent]
    hints: list[ContentHint] = Field(default_factory=list)
    metadata: dict = Field(default_factory=dict)
    assetRefs: list[str] = Field(default_factory=list)
    accessibilityOverrides: dict | None = None
    contentVersion: int = Field(default=1, ge=1)
    estimatedSeconds: int = Field(default=60, ge=1)
    publicationState: PublicationState = "published"

    @field_validator("localizedContent")
    @classmethod
    def _requires_vietnamese(
        cls, value: dict[str, LocalizedLevelContent]
    ) -> dict[str, LocalizedLevelContent]:
        if "vi" not in value:
            raise ValueError(
                "localizedContent must include 'vi' (the documented "
                "fallback locale, see docs/localization.md)"
            )
        return value

    @property
    def age_band(self) -> AgeBand | None:
        return self.metadata.get("ageGroup")

    @property
    def skill_tags(self) -> list[str]:
        return list(self.metadata.get("skillIds") or [])


def validate_content_item(data: dict) -> tuple[ContentItem | None, list[str]]:
    """Returns (parsed_item, errors). parsed_item is None iff errors is non-empty."""
    try:
        return ContentItem.model_validate(data), []
    except Exception as exc:  # pydantic.ValidationError, but keep this generic
        message = str(exc)
        return None, [message]
