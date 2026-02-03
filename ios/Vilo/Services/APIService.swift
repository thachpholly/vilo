import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case server(String)
    case unauthorized
    case networkError(Error)
}

class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        #if DEBUG
        self.baseURL = "http://localhost:3000/api"
        #else
        self.baseURL = "https://api.vilo.app/api"
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Auth

    func sendOTP(phone: String) async throws {
        let body = ["phone": phone]
        let _: SendOTPResponse = try await post("/auth/send-otp", body: body)
    }

    func verifyOTP(phone: String, code: String) async throws -> VerifyOTPResponse {
        let body = ["phone": phone, "code": code]
        return try await post("/auth/verify-otp", body: body)
    }

    func refreshToken() async throws -> String {
        struct RefreshResponse: Codable {
            let token: String
        }
        let response: RefreshResponse = try await post("/auth/refresh", body: [:], authenticated: true)
        return response.token
    }

    // MARK: - User

    func getMe() async throws -> User {
        return try await get("/users/me", authenticated: true)
    }

    func updateProfile(name: String?, avatar: String?) async throws -> User {
        var body: [String: String] = [:]
        if let name = name { body["name"] = name }
        if let avatar = avatar { body["avatar"] = avatar }

        let response: ProfileUpdateResponse = try await patch("/users/me", body: body, authenticated: true)
        return response.user
    }

    func findUser(by identifier: String) async throws -> User {
        return try await get("/users/find/\(identifier)", authenticated: true)
    }

    // MARK: - Keys

    func uploadKeys(_ keys: PublicKeys) async throws {
        struct KeysResponse: Codable { let success: Bool }
        let _: KeysResponse = try await post("/users/keys", body: keys, authenticated: true)
    }

    func getPublicKey(for phone: String) async throws -> UserPublicKey {
        return try await get("/users/keys/\(phone)", authenticated: true)
    }

    // MARK: - Private Methods

    private func get<T: Decodable>(_ path: String, authenticated: Bool = false) async throws -> T {
        return try await request(path, method: "GET", body: nil as String?, authenticated: authenticated)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B, authenticated: Bool = false) async throws -> T {
        return try await request(path, method: "POST", body: body, authenticated: authenticated)
    }

    private func patch<T: Decodable, B: Encodable>(_ path: String, body: B, authenticated: Bool = false) async throws -> T {
        return try await request(path, method: "PATCH", body: body, authenticated: authenticated)
    }

    private func request<T: Decodable, B: Encodable>(_ path: String, method: String, body: B?, authenticated: Bool) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = Storage.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        case 401:
            throw APIError.unauthorized

        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.server(errorResponse.error)
            }
            throw APIError.server("Unknown error")
        }
    }
}

private struct ErrorResponse: Codable {
    let error: String
}
