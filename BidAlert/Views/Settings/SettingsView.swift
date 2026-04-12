import MessageUI
import SwiftData
import SwiftUI

/// 설정 화면
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    var notificationService: NotificationService

    @Query private var allHistory: [NotificationHistory]
    @Query private var allKeywords: [Keyword]

    @State private var showResetAlert = false
    @State private var showMailComposer = false

    var body: some View {
        List {
            // 알림 설정
            Section("알림 설정") {
                HStack {
                    Label("알림 상태", systemImage: "bell.fill")
                    Spacer()
                    Text(notificationService.isAuthorized ? "켜짐" : "꺼짐")
                        .foregroundStyle(
                            notificationService.isAuthorized
                                ? DS.Colors.success
                                : DS.Colors.danger
                        )
                        .fontWeight(.medium)
                    Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(
                            notificationService.isAuthorized
                                ? DS.Colors.success
                                : DS.Colors.danger
                        )
                }

                Button {
                    notificationService.openSettings()
                } label: {
                    Label("알림 설정 변경", systemImage: "gear")
                }
            }

            // 데이터 관리
            Section("데이터 관리") {
                LabeledContent {
                    Text("\(allHistory.count)건")
                        .foregroundStyle(DS.Colors.textSecondary)
                } label: {
                    Label("저장된 알림", systemImage: "tray.full.fill")
                }

                LabeledContent {
                    Text("\(allKeywords.count)개")
                        .foregroundStyle(DS.Colors.textSecondary)
                } label: {
                    Label("등록된 키워드", systemImage: "tag.fill")
                }

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("전체 데이터 초기화", systemImage: "trash")
                }
            }

            // 정보
            Section("정보") {
                // 문의하기
                Button {
                    sendEmail()
                } label: {
                    Label("문의하기", systemImage: "envelope.fill")
                }

                // 앱 평가
                Link(destination: URL(string: "https://apps.apple.com/app/id000000000")!) {
                    Label("앱 평가하기", systemImage: "star.fill")
                }

                // 오픈소스
                NavigationLink {
                    openSourceView
                } label: {
                    Label("오픈소스 라이선스", systemImage: "doc.text.fill")
                }

                LabeledContent {
                    Text(appVersion)
                        .foregroundStyle(DS.Colors.textSecondary)
                } label: {
                    Label("앱 버전", systemImage: "info.circle.fill")
                }
            }

            // 면책 조항
            Section {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DS.Colors.accentFallback)
                        Text("면책 조항")
                            .font(.subheadline.bold())
                    }
                    Text("본 앱은 조달청(나라장터)의 공식 앱이 아닙니다. 공공데이터포털 OpenAPI를 활용한 비공식 서비스이며, 데이터의 정확성은 원본 시스템(나라장터)을 기준으로 합니다.")
                        .font(.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("전체 데이터를 초기화합니다", isPresented: $showResetAlert) {
            Button("초기화", role: .destructive) { resetAllData() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("등록된 모든 키워드와 알림 히스토리가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
    }

    // MARK: - Open Source

    private var openSourceView: some View {
        List {
            Section("사용된 오픈소스") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Firebase iOS SDK")
                        .font(.subheadline.bold())
                    Text("Apache License 2.0")
                        .font(.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .navigationTitle("오픈소스 라이선스")
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func resetAllData() {
        // 모든 키워드 토픽 구독 해제 후 삭제
        for keyword in allKeywords {
            KeywordManager.removeKeyword(keyword, context: modelContext)
        }
        // 히스토리 전체 삭제
        for history in allHistory {
            modelContext.delete(history)
        }
    }

    private func sendEmail() {
        let email = "your-email@example.com"
        let subject = "[입찰알리미] 문의"
        let body = "\n\n---\n기기: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)\n앱 버전: \(appVersion)"

        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}
