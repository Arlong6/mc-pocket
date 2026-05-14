import Foundation
import Security

/// Connection info for the user's paired Mac running Mission Control.
/// Lives in the iOS keychain once paired via QR.
struct PairedServer: Codable, Equatable {
    let host: String     // hostname, Tailscale magic-dns name, or IP
    let port: Int
    let secret: String   // shared secret for HMAC auth
    let nickname: String // human-readable label, e.g. "Arlong MBP"

    var baseURL: URL {
        URL(string: "http://\(host):\(port)")!
    }

    /// Parse a `mcpocket://pair?host=…&port=…&secret=…&nick=…` URL produced
    /// by the Mac side. Returns nil if any required field is missing.
    static func parse(pairingURL: String) -> PairedServer? {
        guard let comps = URLComponents(string: pairingURL),
              comps.scheme?.lowercased() == "mcpocket",
              comps.host?.lowercased() == "pair"
        else { return nil }

        var dict: [String: String] = [:]
        for q in comps.queryItems ?? [] {
            if let v = q.value { dict[q.name] = v }
        }
        guard let host = dict["host"],
              let portStr = dict["port"], let port = Int(portStr),
              let secret = dict["secret"]
        else { return nil }

        return PairedServer(
            host: host,
            port: port,
            secret: secret,
            nickname: dict["nick"] ?? "Mac"
        )
    }
}

// MARK: - Keychain persistence

extension PairedServer {
    private static let service = "com.arlong.mcpocket"
    private static let account = "paired-server-v1"

    static func loadFromKeychain() -> PairedServer? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let decoded = try? JSONDecoder().decode(PairedServer.self, from: data)
        else { return nil }
        return decoded
    }

    func saveToKeychain() throws {
        let data = try JSONEncoder().encode(self)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "MCPocket.Keychain", code: Int(status))
        }
    }

    static func removeFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
