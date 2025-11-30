import Foundation
import CoreData

// MARK: - Article Cache Service
/// Caches the news feed for offline access
final class ArticleCacheService {
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Cache Operations
    
    /// Cache articles from the feed
    func cacheArticles(_ articles: [Article]) {
        // Clear old cache first
        clearCache()
        
        // Save new articles
        for (index, article) in articles.enumerated() {
            let cached = CachedArticle(context: context)
            cached.articleId = article.id
            cached.webTitle = article.webTitle
            cached.sectionId = article.sectionId
            cached.sectionName = article.sectionName
            cached.webUrl = article.webUrl
            cached.webPublicationDate = article.webPublicationDate
            cached.thumbnailUrl = article.fields?.thumbnail
            cached.cachedAt = Date()
            cached.orderIndex = Int32(index)
        }
        
        persistenceController.save()
    }
    
    /// Get cached articles
    func getCachedArticles() -> [Article] {
        let request: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedArticle.orderIndex, ascending: true)]
        
        do {
            let cached = try context.fetch(request)
            return cached.compactMap { convertToArticle($0) }
        } catch {
            print("Failed to fetch cached articles: \(error)")
            return []
        }
    }
    
    /// Check if cache exists and is fresh (less than 1 hour old)
    func hasFreshCache() -> Bool {
        let request: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedArticle.cachedAt, ascending: false)]
        
        do {
            if let newest = try context.fetch(request).first,
               let cachedAt = newest.cachedAt {
                let hourAgo = Date().addingTimeInterval(-3600)
                return cachedAt > hourAgo
            }
        } catch {
            print("Failed to check cache: \(error)")
        }
        
        return false
    }
    
    /// Check if any cache exists (regardless of freshness)
    func hasCache() -> Bool {
        let request: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Clear the cache
    func clearCache() {
        let request: NSFetchRequest<NSFetchRequestResult> = CachedArticle.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func convertToArticle(_ cached: CachedArticle) -> Article? {
        guard let articleId = cached.articleId,
              let webTitle = cached.webTitle,
              let webUrl = cached.webUrl else {
            return nil
        }
        
        let fields: ArticleFields?
        if let thumbnailUrl = cached.thumbnailUrl {
            fields = ArticleFields(thumbnail: thumbnailUrl, trailText: nil)
        } else {
            fields = nil
        }
        
        return Article(
            id: articleId,
            type: "article",
            sectionId: cached.sectionId ?? "",
            sectionName: cached.sectionName ?? "",
            webPublicationDate: cached.webPublicationDate ?? "",
            webTitle: webTitle,
            webUrl: webUrl,
            apiUrl: "",
            isHosted: false,
            pillarId: nil,
            pillarName: nil,
            fields: fields
        )
    }
}

