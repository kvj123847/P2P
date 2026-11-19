"""
Central configuration for the session-engine service.

All values are overridable via environment variables so the same code runs
in POC / staging / production without edits (Phase 9 — Production hardening,
Section 13 of the roadmap: "replace every POC shortcut ... via environment
variables").
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _env_bool(name: str, default: bool) -> bool:
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class Settings:
    environment: str = os.getenv("APP_ENV", os.getenv("NODE_ENV", "development"))
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = _env_int("PORT", 8001)

    # --- Person 1 backend integration (auth / tier / payment source of truth) ---
    p1_base_url: str = os.getenv("P1_BASE_URL", "https://example-core-api.internal")
    p1_service_token: str = os.getenv("P1_SERVICE_TOKEN", "")
    p1_timeout_seconds: float = float(os.getenv("P1_TIMEOUT_SECONDS", "5.0"))

    # --- Video provider (Section 3 / Section 5 POC) ---
    video_provider_name: str = os.getenv("VIDEO_PROVIDER", "agora")
    agora_app_id: str = os.getenv("AGORA_APP_ID", "")
    agora_app_certificate: str = os.getenv("AGORA_APP_CERTIFICATE", "")
    video_token_ttl_seconds: int = _env_int("VIDEO_TOKEN_TTL_SECONDS", 600)  # 5-10 min, Section 19

    # --- Session lifecycle timing ---
    join_window_grace_seconds: int = _env_int("JOIN_WINDOW_GRACE_SECONDS", 600)  # 10 min, Section 4
    reconnect_grace_seconds: int = _env_int("RECONNECT_GRACE_SECONDS", 45)
    session_reminder_lead_seconds: int = _env_int("SESSION_REMINDER_LEAD_SECONDS", 15 * 60)

    # --- Group video ---
    max_group_room_capacity: int = _env_int("MAX_GROUP_ROOM_CAPACITY", 12)

    # --- Chat ---
    chat_page_size: int = _env_int("CHAT_PAGE_SIZE", 30)

    # --- Feature flags ---
    strict_tier_reverify_on_every_join: bool = _env_bool("STRICT_TIER_REVERIFY", True)
    dev_mock_data: bool = _env_bool("DEV_MOCK_DATA", False)

    # --- Push delivery (infra is P1/shared platform concern; these are just client ids) ---
    fcm_server_key: str = os.getenv("FCM_SERVER_KEY", "")
    apns_key_id: str = os.getenv("APNS_KEY_ID", "")


settings = Settings()
