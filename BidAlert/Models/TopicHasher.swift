import CryptoKit
import Foundation

/// 키워드 → FCM Topic 해시 변환
///
/// ⚠️ 서버(Python)의 `topic_hasher.py`와 반드시 동일한 결과를 생성해야 합니다.
///
/// 정규화 순서: trimmingCharacters → lowercased → SHA256 → hex prefix(16)
///
/// 검증 기준값:
/// - "cctv"     → "b29dbba57df61de7"
/// - "소프트웨어" → "465f222a27475e7f"
/// - "ai"       → "32e83e92d45d71f6"
/// - "측량"     → "5f66b02e337d9504"
enum TopicHasher {

    enum NotificationType: String {
        case bid = "bid"
        case prebid = "pre"
    }

    /// 키워드를 FCM Topic 이름으로 변환
    /// - Parameters:
    ///   - keyword: 원본 키워드 (예: "CCTV", "소프트웨어")
    ///   - type: 알림 유형 (.bid 또는 .prebid)
    /// - Returns: FCM Topic 이름 (예: "bid_b29dbba57df61de7")
    static func topicName(for keyword: String, type: NotificationType) -> String {
        let prefix = type == .bid ? "bid_" : "pre_"
        let normalized = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        let hash = SHA256.hash(data: Data(normalized.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        let truncated = String(hex.prefix(16))
        return "\(prefix)\(truncated)"
    }

    /// 키워드의 입찰공고 + 사전규격 토픽 이름 동시 반환
    static func allTopics(for keyword: String) -> (bid: String, pre: String) {
        return (
            bid: topicName(for: keyword, type: .bid),
            pre: topicName(for: keyword, type: .prebid)
        )
    }
}
