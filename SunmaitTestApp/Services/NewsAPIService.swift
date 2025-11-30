import Foundation

// MARK: - News API Service Protocol
protocol NewsAPIServiceProtocol {
    func fetchNews(page: Int, pageSize: Int) async throws -> GuardianData
}

// MARK: - News API Service
final class NewsAPIService: NewsAPIServiceProtocol {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    func fetchNews(page: Int = 1, pageSize: Int = 10) async throws -> GuardianData {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page-size", value: String(pageSize)),
            URLQueryItem(name: "show-fields", value: "thumbnail,trailText")
        ]
        
        let response: GuardianResponse = try await apiService.request("/guardian", queryItems: queryItems)
        return response.response
    }
}

