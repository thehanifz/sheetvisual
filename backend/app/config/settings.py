from __future__ import annotations

from enum import StrEnum
from functools import lru_cache

from pydantic import Field, PostgresDsn, RedisDsn, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppEnvironment(StrEnum):
    LOCAL = "local"
    DEV = "dev"
    STAGING = "staging"
    PRODUCTION = "production"


class Settings(BaseSettings):
    """Validated runtime configuration for Phase 1 infrastructure only.

    URLs are configuration references, not active connections. Database access,
    tenant context, schema, RLS, authentication, and domain behavior remain out
    of scope until their separately authorized phases.
    """

    model_config = SettingsConfigDict(
        env_prefix="APP_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="forbid",
    )

    environment: AppEnvironment = Field(alias="ENV")
    database_url: PostgresDsn = Field(alias="DATABASE_URL")
    redis_url: RedisDsn = Field(alias="REDIS_URL")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")


@lru_cache
def get_settings() -> Settings:
    """Return validated settings or fail fast with a validation error."""
    return Settings()


def validate_settings() -> Settings:
    """Validate required configuration without creating network connections."""
    return get_settings()


__all__ = [
    "AppEnvironment",
    "Settings",
    "ValidationError",
    "get_settings",
    "validate_settings",
]
