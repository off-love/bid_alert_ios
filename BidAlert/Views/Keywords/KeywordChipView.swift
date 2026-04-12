import SwiftData
import SwiftUI

/// 키워드 Chip 뷰
struct KeywordChipView: View {
    let keyword: Keyword
    var onTap: () -> Void
    var onDelete: () -> Void

    /// 알림 유형에 따른 아이콘
    private var typeIcon: String? {
        switch keyword.notificationType {
        case "bid": return "doc.text.fill"
        case "pre": return "clipboard.fill"
        default: return nil  // "all"이면 아이콘 없음
        }
    }

    /// 알림 유형에 따른 색상
    private var typeColor: Color {
        switch keyword.notificationType {
        case "bid": return DS.Colors.primaryFallback
        case "pre": return DS.Colors.prebid
        default: return DS.Colors.primaryFallback
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            // 알림 유형 아이콘
            if let icon = typeIcon {
                Image(systemName: icon)
                    .font(.caption2)
            }

            Text(keyword.text)
                .font(.subheadline.weight(.medium))
                .strikethrough(!keyword.isActive, color: DS.Colors.textSecondary)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundStyle(keyword.isActive ? typeColor : DS.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            keyword.isActive
                ? typeColor.opacity(0.1)
                : Color.gray.opacity(0.1)
        )
        .foregroundStyle(
            keyword.isActive
                ? typeColor
                : DS.Colors.textSecondary
        )
        .clipShape(Capsule())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(keyword.text) 키워드, \(keyword.notificationType == "bid" ? "입찰공고" : keyword.notificationType == "pre" ? "사전규격" : "전체")")
        .accessibilityHint("탭하여 설정을 변경하세요")
    }
}

// MARK: - 키워드 상세 바텀시트

struct KeywordDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var keyword: Keyword

    var body: some View {
        NavigationStack {
            List {
                // 알림 유형
                Section("알림 유형") {
                    Picker("유형 선택", selection: Binding(
                        get: { keyword.notificationType },
                        set: { KeywordManager.updateNotificationType(keyword, type: $0) }
                    )) {
                        Text("전체").tag("all")
                        Text("입찰공고만").tag("bid")
                        Text("사전규격만").tag("pre")
                    }
                    .pickerStyle(.segmented)
                }

                // 일시중지
                Section {
                    Toggle("알림 받기", isOn: Binding(
                        get: { keyword.isActive },
                        set: { _ in KeywordManager.toggleActive(keyword) }
                    ))
                }

                // 토픽 정보 (디버그용)
                Section("토픽 해시") {
                    LabeledContent("입찰공고", value: keyword.bidTopicHash)
                        .font(.caption)
                    LabeledContent("사전규격", value: keyword.preTopicHash)
                        .font(.caption)
                }

                // 삭제
                Section {
                    Button(role: .destructive) {
                        KeywordManager.removeKeyword(keyword, context: modelContext)
                        dismiss()
                    } label: {
                        Label("키워드 삭제", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(keyword.text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
