#!/usr/bin/env python3
"""
keywords.json의 placeholder 토픽 해시를 실제 SHA256 해시로 갱신합니다.

사용법:
    python scripts/generate_topic_hashes.py
"""

import json
import sys
from pathlib import Path

# 프로젝트 루트를 PYTHONPATH에 추가
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.core.topic_hasher import get_all_topic_names


def main():
    keywords_path = project_root / "data" / "keywords.json"

    with open(keywords_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    updated = 0
    for kw in data["keywords"]:
        topics = get_all_topic_names(kw["original"])
        if kw["bid_topic"] != topics["bid_topic"] or kw["pre_topic"] != topics["pre_topic"]:
            kw["bid_topic"] = topics["bid_topic"]
            kw["pre_topic"] = topics["pre_topic"]
            updated += 1
            print(f"  ✓ {kw['original']:12s} → bid={topics['bid_topic']}, pre={topics['pre_topic']}")

    with open(keywords_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n✅ {updated}개 키워드 해시 업데이트 완료")


if __name__ == "__main__":
    main()
