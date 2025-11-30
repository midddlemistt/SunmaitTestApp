import Foundation

// MARK: - API Configuration
enum APIConfig {
    static let baseURL = "https://us-central1-server-side-functions.cloudfunctions.net"
    static let authorizationHeader = "alexander-timofeev"
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case noData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code, let reason):
            return "Server error (\(code)): \(reason)"
        case .noData:
            return "No data received"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - API Service Protocol
protocol APIServiceProtocol {
    func request<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]?) async throws -> T
}

// MARK: - API Service
final class APIService: APIServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        // Build URL
        guard var urlComponents = URLComponents(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIConfig.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        // Handle error responses
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode >= 400 {
            // Try to decode error response
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error.statusCode, errorResponse.error.reason)
            }
            throw APIError.serverError(httpResponse.statusCode, "Unknown error")
        }
        
        // Decode response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

