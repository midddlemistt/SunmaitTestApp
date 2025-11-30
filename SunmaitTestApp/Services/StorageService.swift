import Foundation
import CoreData
import Combine

// MARK: - List Type
enum SavedListType: String {
    case favorite
    case blocked
}

// MARK: - Storage Service Protocol
protocol StorageServiceProtocol {
    func addArticle(_ article: Article, to listType: SavedListType)
    func removeArticle(id: String, from listType: SavedListType)
    func isArticleSaved(id: String, in listType: SavedListType) -> Bool
    func getArticleIds(for listType: SavedListType) -> Set<String>
    func getSavedArticles(for listType: SavedListType) -> [Article]
    func toggleFavorite(article: Article)
    func toggleBlocked(article: Article)
}

// MARK: - Storage Service
final class StorageService: StorageServiceProtocol, ObservableObject {
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    // Published properties for reactive updates
    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var blockedIds: Set<String> = []
    @Published private(set) var favoriteArticles: [Article] = []
    @Published private(set) var blockedArticles: [Article] = []
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadSavedArticles()
    }
    
    // MARK: - Private Methods
    
    private func loadSavedArticles() {
        favoriteIds = getArticleIds(for: .favorite)
        blockedIds = getArticleIds(for: .blocked)
        favoriteArticles = getSavedArticles(for: .favorite)
        blockedArticles = getSavedArticles(for: .blocked)
    }
    
    private func fetchSavedArticle(id: String, listType: SavedListType) -> SavedArticle? {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.predicate = NSPredicate(format: "articleId == %@ AND listType == %@", id, listType.rawValue)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch saved article: \(error)")
            return nil
        }
    }
    
    private func convertToArticle(_ savedArticle: SavedArticle) -> Article? {
        guard let articleId = savedArticle.articleId,
              let webTitle = savedArticle.webTitle,
              let webUrl = savedArticle.webUrl else {
            return nil
        }
        
        let fields: ArticleFields?
        if let thumbnailUrl = savedArticle.thumbnailUrl {
            fields = ArticleFields(thumbnail: thumbnailUrl, trailText: nil)
        } else {
            fields = nil
        }
        
        return Article(
            id: articleId,
            type: "article",
            sectionId: savedArticle.sectionId ?? "",
            sectionName: savedArticle.sectionName ?? "",
            webPublicationDate: savedArticle.webPublicationDate ?? "",
            webTitle: webTitle,
            webUrl: webUrl,
            apiUrl: "",
            isHosted: false,
            pillarId: nil,
            pillarName: nil,
            fields: fields
        )
    }
    
    // MARK: - Public Methods
    
    func addArticle(_ article: Article, to listType: SavedListType) {
        // Check if already exists
        guard fetchSavedArticle(id: article.id, listType: listType) == nil else { return }
        
        let savedArticle = SavedArticle(context: context)
        savedArticle.articleId = article.id
        savedArticle.listType = listType.rawValue
        savedArticle.addedAt = Date()
        
        // Save full article data
        savedArticle.webTitle = article.webTitle
        savedArticle.sectionId = article.sectionId
        savedArticle.sectionName = article.sectionName
        savedArticle.webUrl = article.webUrl
        savedArticle.webPublicationDate = article.webPublicationDate
        savedArticle.thumbnailUrl = article.fields?.thumbnail
        
        persistenceController.save()
        
        // Update published properties
        switch listType {
        case .favorite:
            favoriteIds.insert(article.id)
            favoriteArticles.append(article)
        case .blocked:
            blockedIds.insert(article.id)
            blockedArticles.append(article)
        }
    }
    
    func removeArticle(id: String, from listType: SavedListType) {
        guard let savedArticle = fetchSavedArticle(id: id, listType: listType) else { return }
        
        context.delete(savedArticle)
        persistenceController.save()
        
        // Update published properties
        switch listType {
        case .favorite:
            favoriteIds.remove(id)
            favoriteArticles.removeAll { $0.id == id }
        case .blocked:
            blockedIds.remove(id)
            blockedArticles.removeAll { $0.id == id }
        }
    }
    
    func isArticleSaved(id: String, in listType: SavedListType) -> Bool {
        switch listType {
        case .favorite:
            return favoriteIds.contains(id)
        case .blocked:
            return blockedIds.contains(id)
        }
    }
    
    func getArticleIds(for listType: SavedListType) -> Set<String> {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.predicate = NSPredicate(format: "listType == %@", listType.rawValue)
        
        do {
            let results = try context.fetch(request)
            return Set(results.compactMap { $0.articleId })
        } catch {
            print("Failed to fetch article IDs: \(error)")
            return []
        }
    }
    
    func getSavedArticles(for listType: SavedListType) -> [Article] {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.predicate = NSPredicate(format: "listType == %@", listType.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedArticle.addedAt, ascending: false)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { convertToArticle($0) }
        } catch {
            print("Failed to fetch saved articles: \(error)")
            return []
        }
    }
    
    func toggleFavorite(article: Article) {
        if isArticleSaved(id: article.id, in: .favorite) {
            removeArticle(id: article.id, from: .favorite)
        } else {
            addArticle(article, to: .favorite)
        }
    }
    
    func toggleBlocked(article: Article) {
        if isArticleSaved(id: article.id, in: .blocked) {
            removeArticle(id: article.id, from: .blocked)
        } else {
            // When blocking, also remove from favorites
            removeArticle(id: article.id, from: .favorite)
            addArticle(article, to: .blocked)
        }
    }
}
