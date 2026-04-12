import SwiftData
import SwiftUI
import UserNotifications

/// 알림 권한 및 히스토리 관리 서비스
@Observable
final class NotificationService {
    var isAuthorized: Bool = false
    var unreadCount: Int = 0

    init() {
        checkAuthorizationStatus()
    }

    /// 알림 권한 상태 확인 (포그라운드 복귀 시마다 호출)
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// 알림 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { self.isAuthorized = granted }
            return granted
        } catch {
            print("❌ 알림 권한 요청 실패: \(error)")
            return false
        }
    }

    /// 시스템 설정 앱으로 이동
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// FCM data payload → NotificationHistory로 변환 후 SwiftData에 저장
    static func saveNotification(data: [String: String], context: ModelContext) {
        let noticeId = data["noticeId"] ?? ""
        guard !noticeId.isEmpty else { return }

        // 중복 체크
        let descriptor = FetchDescriptor<NotificationHistory>(
            predicate: #Predicate { $0.noticeId == noticeId }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // 이미 저장된 알림
        }

        let history = NotificationHistory(from: data)
        context.insert(history)

        // 오래된 데이터 정리 (30일 이상)
        cleanupOldRecords(context: context)
    }

    /// 미확인 알림 수 업데이트
    func updateUnreadCount(context: ModelContext) {
        let descriptor = FetchDescriptor<NotificationHistory>(
            predicate: #Predicate { $0.isRead == false }
        )
        unreadCount = (try? context.fetchCount(descriptor)) ?? 0
    }

    /// 30일 이상 된 알림 자동 삭제
    private static func cleanupOldRecords(context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<NotificationHistory>(
            predicate: #Predicate { $0.receivedAt < cutoff }
        )

        if let oldRecords = try? context.fetch(descriptor) {
            for record in oldRecords {
                context.delete(record)
            }
        }

        // 최대 1,000건 제한
        let allDescriptor = FetchDescriptor<NotificationHistory>(
            sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]
        )

        if let all = try? context.fetch(allDescriptor), all.count > 1000 {
            for record in all.suffix(from: 1000) {
                context.delete(record)
            }
        }
    }
}
