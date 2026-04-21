import Foundation
import CryptoKit

func topicName(for keyword: String, type: String, category: String = "s") -> String {
    let prefix = "\(type)_\(category)_"
    let normalized = keyword.precomposedStringWithCanonicalMapping
        .trimmingCharacters(in: .whitespaces)
        .lowercased()
    let hash = SHA256.hash(data: Data(normalized.utf8))
    let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
    let truncated = String(hex.prefix(16))
    return "\(prefix)\(truncated)"
}

print(topicName(for: "소프트웨어", type: "bid", category: "s"))
