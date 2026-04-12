import Foundation
import SwiftData

/// 사용자가 등록한 키워드
@Model
final class Keyword {
    @Attribute(.unique) var id: UUID
    var text: String               // 원본 키워드 ("CCTV")
    var bidTopicHash: String       // "bid_b29dbba57df61de7"
    var preTopicHash: String       // "pre_b29dbba57df61de7"
    var notificationType: String   // "bid" | "pre" | "all"
    var isActive: Bool             // 일시중지 여부
    var createdAt: Date

    init(text: String, notificationType: String = "all") {
        self.id = UUID()
        self.text = text
        let topics = TopicHasher.allTopics(for: text)
        self.bidTopicHash = topics.bid
        self.preTopicHash = topics.pre
        self.notificationType = notificationType
        self.isActive = true
        self.createdAt = Date()
    }

    /// 이 키워드가 구독해야 하는 토픽 목록
    var activeTopics: [String] {
        guard isActive else { return [] }
        switch notificationType {
        case "bid":
            return [bidTopicHash]
        case "pre":
            return [preTopicHash]
        default: // "all"
            return [bidTopicHash, preTopicHash]
        }
    }

    /// 이 키워드의 모든 토픽 (구독 해제 시 사용)
    var allTopics: [String] {
        return [bidTopicHash, preTopicHash]
    }
}
