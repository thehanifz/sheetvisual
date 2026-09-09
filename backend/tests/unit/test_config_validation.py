from __future__ import annotations

from pydantic import ValidationError

from app.config.settings import AppEnvironment, Settings


def test_settings_accept_valid_local_environment() -> None:
    settings = Settings(
        ENV=AppEnvironment.LOCAL,
        DATABASE_URL="postgresql://sheetviz:sheetviz@localhost:5432/sheetviz",
        REDIS_URL="redis://localhost:6379/0",
    )

    assert settings.environment is AppEnvironment.LOCAL
    assert str(settings.database_url).startswith("postgresql://")
    assert str(settings.redis_url).startswith("redis://")


def test_settings_fail_fast_when_required_database_url_missing() -> None:
    try:
        Settings(ENV="local", REDIS_URL="redis://localhost:6379/0")
    except ValidationError as error:
        missing_fields = {item["loc"][0] for item in error.errors()}
        assert "DATABASE_URL" in missing_fields
    else:
        raise AssertionError("Expected missing APP_DATABASE_URL to fail validation")


def test_settings_reject_unknown_configuration() -> None:
    try:
        Settings(
            ENV="local",
            DATABASE_URL="postgresql://sheetviz:sheetviz@localhost:5432/sheetviz",
            REDIS_URL="redis://localhost:6379/0",
            UNKNOWN_SETTING="not-allowed",
        )
    except ValidationError:
        pass
    else:
        raise AssertionError("Expected unknown configuration to fail validation")
