import Foundation

// MARK: - List Item (Article or Navigation Block)
enum ListItem: Identifiable, Equatable {
    case article(Article)
    case navigationBlock(NavigationBlock)
    
    var id: String {
        switch self {
        case .article(let article):
            return "article_\(article.id)"
        case .navigationBlock(let block):
            return "nav_\(block.id)"
        }
    }
}

