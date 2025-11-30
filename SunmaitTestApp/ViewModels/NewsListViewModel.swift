import Foundation
import Combine

// MARK: - Tab Selection
enum NewsTab: Int, CaseIterable {
    case all = 0
    case favorites = 1
    case blocked = 2
    
    var title: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .blocked: return "Blocked"
        }
    }
}

// MARK: - View State
enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    case empty
    case offline // New state for offline mode
}

// MARK: - News List ViewModel
@MainActor
final class NewsListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var articles: [Article] = []
    @Published var navigationBlocks: [NavigationBlock] = []
    @Published var selectedTab: NewsTab = .all
    @Published var viewState: ViewState = .idle
    @Published var isLoadingMore = false
    @Published var showBlockAlert = false
    @Published var showUnblockAlert = false
    @Published var articleToBlock: Article?
    @Published var articleToUnblock: Article?
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var isOffline = false
    
    // MARK: - Pagination
    
    private var currentPage = 1
    private var totalPages = 1
    private let pageSize = 10
    private var hasMorePages: Bool {
        currentPage < totalPages
    }
    
    // MARK: - Dependencies
    
    private let newsAPIService: NewsAPIServiceProtocol
    private let navigationAPIService: NavigationAPIServiceProtocol
    private let cacheService: ArticleCacheService
    let storageService: StorageService
    
    // Cached articles from CoreData (loaded once)
    private var cachedArticles: [Article] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var listItems: [ListItem] {
        let filteredArticles = filteredArticles
        guard !filteredArticles.isEmpty else { return [] }
        
        // Only insert navigation blocks in "All" tab
        guard selectedTab == .all, !navigationBlocks.isEmpty else {
            return filteredArticles.map { .article($0) }
        }
        
        var items: [ListItem] = []
        
        // Fixed positions for navigation blocks: after 3rd, 6th, 9th article
        let blockPositions = [3, 6, 9]
        var blockIndex = 0
        
        for (index, article) in filteredArticles.enumerated() {
            items.append(.article(article))
            
            let articleNumber = index + 1
            if blockPositions.contains(articleNumber) && blockIndex < navigationBlocks.count {
                items.append(.navigationBlock(navigationBlocks[blockIndex]))
                blockIndex += 1
            }
        }
        
        return items
    }
    
    var filteredArticles: [Article] {
        switch selectedTab {
        case .all:
            // Filter out blocked articles from main list
            return articles.filter { !storageService.blockedIds.contains($0.id) }
        case .favorites:
            // First try loaded articles, then CoreData saved articles
            return getArticlesForIds(storageService.favoriteIds, fallback: storageService.favoriteArticles)
        case .blocked:
            // First try loaded articles, then CoreData saved articles
            return getArticlesForIds(storageService.blockedIds, fallback: storageService.blockedArticles)
        }
    }
    
    /// Get articles by IDs - first from loaded articles, then from fallback
    private func getArticlesForIds(_ ids: Set<String>, fallback: [Article]) -> [Article] {
        var result: [Article] = []
        let allSources = articles + cachedArticles + fallback
        
        for id in ids {
            if let article = allSources.first(where: { $0.id == id }) {
                result.append(article)
            }
        }
        
        return result
    }
    
    var isEmpty: Bool {
        // Always check filteredArticles for consistency
        // For All tab, also check viewState
        switch selectedTab {
        case .all:
            return filteredArticles.isEmpty && (viewState == .loaded || viewState == .offline)
        case .favorites, .blocked:
            // Check both IDs (source of truth) and filtered articles
            return filteredArticles.isEmpty
        }
    }
    
    var emptyStateTitle: String {
        switch selectedTab {
        case .all:
            if isOffline {
                return "No Internet Connection"
            }
            return "No Results"
        case .favorites:
            return "No Favorite News"
        case .blocked:
            return "No Blocked News"
        }
    }
    
    var emptyStateSubtitle: String? {
        switch selectedTab {
        case .all:
            if isOffline {
                return "Check your connection and try again"
            }
            return nil
        case .favorites:
            return "Add articles to favorites to see them here"
        case .blocked:
            return "Blocked articles will appear here"
        }
    }
    
    var emptyStateIcon: String {
        switch selectedTab {
        case .all:
            if isOffline {
                return "wifi.slash"
            }
            return "exclamationmark.circle.fill"
        case .favorites:
            return "heart.circle.fill"
        case .blocked:
            return "nosign"
        }
    }
    
    // MARK: - Initialization
    
    init(
        newsAPIService: NewsAPIServiceProtocol = NewsAPIService(),
        navigationAPIService: NavigationAPIServiceProtocol = NavigationAPIService(),
        storageService: StorageService = StorageService(),
        cacheService: ArticleCacheService = ArticleCacheService()
    ) {
        self.newsAPIService = newsAPIService
        self.navigationAPIService = navigationAPIService
        self.storageService = storageService
        self.cacheService = cacheService
        
        // Load cached articles once at init
        self.cachedArticles = cacheService.getCachedArticles()
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen to storage changes to update UI
        storageService.$favoriteIds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        storageService.$blockedIds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        storageService.$favoriteArticles
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        storageService.$blockedArticles
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() async {
        guard viewState != .loading else { return }
        
        viewState = .loading
        currentPage = 1
        isOffline = false
        
        do {
            async let newsTask = newsAPIService.fetchNews(page: currentPage, pageSize: pageSize)
            async let navigationTask = navigationAPIService.fetchNavigationBlocks()
            
            let (newsData, navBlocks) = try await (newsTask, navigationTask)
            
            articles = newsData.results
            navigationBlocks = navBlocks
            totalPages = newsData.pages
            
            // Cache articles for offline use
            cacheService.cacheArticles(articles)
            cachedArticles = articles
            
            viewState = articles.isEmpty ? .empty : .loaded
        } catch {
            // Try to load from cache if network fails
            loadFromCacheIfAvailable()
            if articles.isEmpty {
                handleError(error)
            }
        }
    }
    
    func refresh() async {
        currentPage = 1
        
        do {
            async let newsTask = newsAPIService.fetchNews(page: currentPage, pageSize: pageSize)
            async let navigationTask = navigationAPIService.fetchNavigationBlocks()
            
            let (newsData, navBlocks) = try await (newsTask, navigationTask)
            
            articles = newsData.results
            navigationBlocks = navBlocks
            totalPages = newsData.pages
            isOffline = false
            
            // Cache articles for offline use
            cacheService.cacheArticles(articles)
            cachedArticles = articles
            
            viewState = articles.isEmpty ? .empty : .loaded
        } catch {
            // Don't change state if we already have data and it's a cancellation
            if error is CancellationError || (error as NSError).code == NSURLErrorCancelled {
                return
            }
            
            // If we have cached data, keep showing it
            if !articles.isEmpty {
                // Just ignore the error, keep current data
                return
            }
            
            handleError(error)
        }
    }
    
    private func loadFromCacheIfAvailable() {
        let cachedArticles = cacheService.getCachedArticles()
        if !cachedArticles.isEmpty {
            articles = cachedArticles
            isOffline = true
            viewState = .offline
        }
    }
    
    func loadMoreIfNeeded(currentItem: ListItem) async {
        // Only load more in "All" tab
        guard selectedTab == .all else { return }
        
        // Check if we're at the last item
        guard let lastItem = listItems.last, lastItem.id == currentItem.id else { return }
        
        // Check if we can load more
        guard hasMorePages && !isLoadingMore else { return }
        
        await loadMore()
    }
    
    private func loadMore() async {
        isLoadingMore = true
        currentPage += 1
        
        do {
            let newsData = try await newsAPIService.fetchNews(page: currentPage, pageSize: pageSize)
            articles.append(contentsOf: newsData.results)
            totalPages = newsData.pages
        } catch {
            currentPage -= 1
            handleError(error)
        }
        
        isLoadingMore = false
    }
    
    // MARK: - Article Actions
    
    func isFavorite(_ article: Article) -> Bool {
        storageService.isArticleSaved(id: article.id, in: .favorite)
    }
    
    func isBlocked(_ article: Article) -> Bool {
        storageService.isArticleSaved(id: article.id, in: .blocked)
    }
    
    func toggleFavorite(_ article: Article) {
        storageService.toggleFavorite(article: article)
    }
    
    func prepareToBlock(_ article: Article) {
        articleToBlock = article
        showBlockAlert = true
    }
    
    func confirmBlock() {
        guard let article = articleToBlock else { return }
        storageService.toggleBlocked(article: article)
        articleToBlock = nil
        showBlockAlert = false
    }
    
    func prepareToUnblock(_ article: Article) {
        articleToUnblock = article
        showUnblockAlert = true
    }
    
    func confirmUnblock() {
        guard let article = articleToUnblock else { return }
        storageService.removeArticle(id: article.id, from: .blocked)
        articleToUnblock = nil
        showUnblockAlert = false
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        // Ignore cancellation errors (happens during pull-to-refresh)
        if error is CancellationError {
            return
        }
        
        // Check for URLError cancelled
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        // Check for network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost:
                isOffline = true
                errorMessage = "No Internet Connection"
                viewState = .offline
                return
            default:
                break
            }
        }
        
        viewState = .error(errorMessage ?? "Something Went Wrong")
        showErrorAlert = true
    }
}
