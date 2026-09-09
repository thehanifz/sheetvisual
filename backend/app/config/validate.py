from __future__ import annotations

import sys

from pydantic import ValidationError

from .settings import validate_settings


def main() -> int:
    try:
        settings = validate_settings()
    except ValidationError as error:
        print("Configuration validation failed.", file=sys.stderr)
        for item in error.errors(include_url=False):
            location = ".".join(str(part) for part in item["loc"])
            print(f"- {location}: {item['msg']}", file=sys.stderr)
        return 1

    print(f"Configuration validation passed for environment: {settings.environment}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
