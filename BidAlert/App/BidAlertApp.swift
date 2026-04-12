import FirebaseCore
import FirebaseMessaging
import SwiftData
import SwiftUI

@main
struct BidAlertApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(for: [Keyword.self, NotificationHistory.self])
    }
}

// MARK: - AppDelegate (Firebase + FCM 설정)

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    /// SwiftData ModelContainer (알림 저장용)
    private lazy var modelContainer: ModelContainer? = {
        try? ModelContainer(for: Keyword.self, NotificationHistory.self)
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // FCM 설정
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // 원격 알림 등록
        application.registerForRemoteNotifications()

        return true
    }

    // APNs 토큰 수신
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 FCM Token: \(fcmToken ?? "nil")")
    }

    // 포그라운드 알림 표시 + SwiftData 저장
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 알림 데이터를 SwiftData에 저장
        saveNotificationToHistory(userInfo: notification.request.content.userInfo)

        completionHandler([.banner, .badge, .sound])
    }

    // 알림 탭 처리 (딥링크) + SwiftData 저장
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 알림 데이터를 SwiftData에 저장 (중복 체크 포함)
        saveNotificationToHistory(userInfo: userInfo)

        // data payload에서 detailUrl 추출
        if let urlString = userInfo["detailUrl"] as? String,
           let url = URL(string: urlString) {
            // 딥링크 처리 → NotificationCenter로 전달
            NotificationCenter.default.post(
                name: .openNotificationDetail,
                object: nil,
                userInfo: ["url": url, "data": userInfo]
            )
        }

        completionHandler()
    }

    // MARK: - 알림 → SwiftData 저장

    /// userInfo 딕셔너리에서 데이터를 추출하여 SwiftData에 저장
    @MainActor
    private func saveNotificationToHistory(userInfo: [AnyHashable: Any]) {
        guard let container = modelContainer else {
            print("❌ ModelContainer 초기화 실패")
            return
        }

        // [AnyHashable: Any] → [String: String] 변환
        var data: [String: String] = [:]
        for (key, value) in userInfo {
            if let k = key as? String {
                data[k] = "\(value)"
            }
        }

        guard !data.isEmpty, data["noticeId"] != nil else {
            print("⚠️ 알림 데이터에 noticeId 없음, 저장 건너뜀")
            return
        }

        let context = container.mainContext
        NotificationService.saveNotification(data: data, context: context)
        print("✅ 알림 히스토리 저장 완료: \(data["title"] ?? "")")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openNotificationDetail = Notification.Name("openNotificationDetail")
}
