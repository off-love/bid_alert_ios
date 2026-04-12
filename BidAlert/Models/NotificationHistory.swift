import Foundation
import SwiftData

/// 수신한 알림 히스토리
@Model
final class NotificationHistory {
    @Attribute(.unique) var noticeId: String   // "R26BK01387264-000"
    var title: String                           // 공고명
    var agency: String                          // 공고기관
    var demandAgency: String                    // 수요기관
    var estimatedPrice: Int64                   // 추정가격
    var closingDate: Date?                      // 마감일
    var noticeDate: Date?                       // 공고일
    var detailUrl: String                       // 상세 URL
    var bidType: String                         // "service"/"goods"/"construction"/"foreign"
    var noticeType: String                      // "bid" or "prebid"
    var keyword: String                         // 매칭 키워드
    var region: String                          // 참가가능지역
    var contractMethod: String                  // 계약방법
    var isRead: Bool                            // 읽음 여부
    var receivedAt: Date                        // 수신 시각

    init(from data: [String: String]) {
        self.noticeId = data["noticeId"] ?? UUID().uuidString
        self.title = data["title"] ?? ""
        self.agency = data["agency"] ?? ""
        self.demandAgency = data["demandAgency"] ?? ""
        self.estimatedPrice = Int64(data["price"] ?? "0") ?? 0
        self.closingDate = Self.parseDate(data["closingDate"] ?? "")
        self.noticeDate = Self.parseDate(data["noticeDate"] ?? "")
        self.detailUrl = data["detailUrl"] ?? ""
        self.bidType = data["bidType"] ?? "service"
        self.noticeType = data["type"] ?? "bid"
        self.keyword = data["keyword"] ?? ""
        self.region = data["region"] ?? ""
        self.contractMethod = data["contractMethod"] ?? ""
        self.isRead = false
        self.receivedAt = Date()
    }

    // MARK: - Computed Properties

    /// D-day 텍스트 (예: "D-14", "D-0(오늘)", "마감")
    var dDayText: String {
        guard let closing = closingDate else { return "" }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: closing)).day ?? 0

        if days < 0 { return "마감" }
        if days == 0 { return "D-0(오늘)" }
        return "D-\(days)"
    }

    /// 마감 임박 여부 (3일 이내)
    var isDeadlineSoon: Bool {
        guard let closing = closingDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: closing).day ?? 0
        return days >= 0 && days <= 3
    }

    /// 가격 표시 포맷 (예: "150,000,000원")
    var priceDisplay: String {
        if estimatedPrice <= 0 { return "미정" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: estimatedPrice)) ?? "0") + "원"
    }

    /// 상대 시간 (예: "30분 전", "2시간 전")
    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: receivedAt, relativeTo: Date())
    }

    /// 업종 표시명
    var bidTypeDisplay: String {
        switch bidType {
        case "service": return "용역"
        case "goods": return "물품"
        case "construction": return "공사"
        case "foreign": return "외자"
        default: return bidType
        }
    }

    /// 입찰공고인지 사전규격인지
    var isBid: Bool { noticeType == "bid" }

    // MARK: - Private

    private static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }

        let formats = [
            "yyyy/MM/dd HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy-MM-dd HH:mm",
            "yyyyMMddHHmmss",
            "yyyyMMddHHmm",
            "yyyyMMdd",
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }
}
