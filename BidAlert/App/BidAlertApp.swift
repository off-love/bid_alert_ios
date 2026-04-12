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

    // 포그라운드 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    // 알림 탭 처리 (딥링크)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

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
}

// MARK: - Notification Names

extension Notification.Name {
    static let openNotificationDetail = Notification.Name("openNotificationDetail")
}
