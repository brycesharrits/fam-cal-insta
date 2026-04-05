import Foundation

enum HTTPMethod: String {
    case GET, POST, PATCH, PUT, DELETE
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case unauthorized
    case insufficientTokens
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        case .unauthorized: return "Please sign in again"
        case .insufficientTokens: return "Not enough tokens. Purchase more to continue."
        case .networkError(let err): return err.localizedDescription
        }
    }
}

actor APIClient {
    let baseURL: URL
    private let session: URLSession
    private(set) var jwtToken: String?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func setToken(_ token: String) {
        self.jwtToken = token
    }

    func clearToken() {
        self.jwtToken = nil
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: (some Encodable)? = nil as String?) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = jwtToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 402:
            throw APIError.insufficientTokens
        default:
            let message = (try? decoder.decode(ErrorResponse.self, from: data))?.error ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    func upload(to presignedURL: URL, data: Data, contentType: String) async throws {
        var req = URLRequest(url: presignedURL)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        let (_, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "Upload failed")
        }
    }
}

private struct ErrorResponse: Decodable {
    let error: String
}
