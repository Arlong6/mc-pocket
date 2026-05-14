import Foundation
import CryptoKit

/// HTTP client against the Mac-side Mission Control server.
///
/// Auth scheme: `Authorization: MC1-HMAC-SHA256 ts=<unix-seconds>;sig=<hex>`
/// where sig = HMAC-SHA256(secret, "\(method)\n\(path)\n\(ts)\n\(sha256(body))").
/// Bearer fallback is intentionally not sent — the Mac side accepts either,
/// but new clients should always sign. See ../SECURITY.md.
struct MissionControlClient {
    let server: PairedServer

    private var session: URLSession {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 6
        cfg.timeoutIntervalForResource = 12
        return URLSession(configuration: cfg)
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func ping() async throws -> Bool {
        let req = signedRequest(method: "GET", path: "/healthz")
        let (_, response) = try await session.data(for: req)
        return (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
    }

    func fetchProjects() async throws -> [Project] {
        try await get("/projects", as: [Project].self)
    }

    func fetchMessages(sessionId: String, after: String? = nil) async throws -> [ChatMessage] {
        var path = "/sessions/\(sessionId)/messages"
        if let after { path += "?after=\(after)" }
        return try await get(path, as: [ChatMessage].self)
    }

    func send(sessionId: String, text: String) async throws {
        try await postEncodable("/sessions/\(sessionId)/send", body: ["text": text])
    }

    func register(deviceToken: String, nickname: String = "iPhone") async throws {
        try await postEncodable("/register-device", body: [
            "token": deviceToken,
            "platform": "ios",
            "nickname": nickname,
        ])
    }

    func updateRules(_ rules: NotificationRules) async throws {
        try await postEncodable("/rules", body: rules)
    }

    // MARK: - Signing

    private func signedRequest(method: String, path: String, body: Data = Data()) -> URLRequest {
        var req = URLRequest(url: server.baseURL.appendingPathComponent(path))
        req.httpMethod = method

        let ts = String(Int(Date().timeIntervalSince1970))
        let bodyHash = SHA256.hash(data: body)
            .map { String(format: "%02x", $0) }.joined()
        // Path-only canonical (no query string) — matches what the server sees
        // post-parsing. Sufficient against replay for our threat model since
        // the Mac trusts callers reachable via Tailscale anyway. Query params
        // remain plaintext on the wire.
        let canonical = "\(method)\n\(path.split(separator: "?").first.map(String.init) ?? path)\n\(ts)\n\(bodyHash)"
        let key = SymmetricKey(data: Data(server.secret.utf8))
        let sig = HMAC<SHA256>.authenticationCode(for: Data(canonical.utf8), using: key)
            .map { String(format: "%02x", $0) }.joined()
        req.setValue("MC1-HMAC-SHA256 ts=\(ts);sig=\(sig)", forHTTPHeaderField: "Authorization")
        if !body.isEmpty {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    // MARK: - Helpers

    private func get<T: Decodable>(_ path: String, as: T.Type) async throws -> T {
        let req = signedRequest(method: "GET", path: path)
        let (data, response) = try await session.data(for: req)
        try Self.validate(response)
        return try Self.decoder.decode(T.self, from: data)
    }

    private func postEncodable<T: Encodable>(_ path: String, body: T) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        let req = signedRequest(method: "POST", path: path, body: data)
        let (_, response) = try await session.data(for: req)
        try Self.validate(response)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "MissionControlClient", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Non-HTTP response"])
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "MissionControlClient", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
    }
}
