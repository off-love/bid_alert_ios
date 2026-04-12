"""
키워드 → FCM Topic 해시 변환

iOS(Swift)와 Python 양쪽에서 동일한 해시를 생성해야 합니다.
정규화 순서: strip() → lower() → SHA256 → hexdigest[:16]
"""

from __future__ import annotations

import hashlib


def topic_name(keyword: str, noti_type: str = "bid") -> str:
    """키워드를 FCM Topic 이름으로 변환

    FCM Topic 이름 규칙: [a-zA-Z0-9-_.~%]{1,900}
    한글 키워드를 SHA256 해시로 변환합니다.

    Args:
        keyword: 원본 키워드 (예: "CCTV", "소프트웨어")
        noti_type: "bid" (입찰공고) 또는 "pre" (사전규격)

    Returns:
        FCM Topic 이름 (예: "bid_682608e4a04d8e01")
    """
    prefix = "bid_" if noti_type == "bid" else "pre_"
    normalized = keyword.strip().lower()
    hex_hash = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16]
    return f"{prefix}{hex_hash}"


def get_all_topic_names(keyword: str) -> dict[str, str]:
    """키워드의 입찰공고/사전규격 토픽 이름을 모두 반환

    Args:
        keyword: 원본 키워드

    Returns:
        {"bid_topic": "bid_...", "pre_topic": "pre_..."}
    """
    return {
        "bid_topic": topic_name(keyword, "bid"),
        "pre_topic": topic_name(keyword, "pre"),
    }
