import Foundation

// MARK: - Navigation API Service Protocol
protocol NavigationAPIServiceProtocol {
    func fetchNavigationBlocks() async throws -> [NavigationBlock]
}

// MARK: - Navigation API Service
final class NavigationAPIService: NavigationAPIServiceProtocol {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    func fetchNavigationBlocks() async throws -> [NavigationBlock] {
        let response: NavigationResponse = try await apiService.request("/navigation", queryItems: nil)
        return response.results
    }
}

