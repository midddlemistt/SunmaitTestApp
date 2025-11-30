import Foundation

// MARK: - Navigation API Response
struct NavigationResponse: Codable {
    let results: [NavigationBlock]
}

// MARK: - Navigation Block Model
struct NavigationBlock: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let subtitle: String?
    let titleSymbol: String?
    let buttonTitle: String
    let buttonSymbol: String?
    let navigation: NavigationType
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, navigation
        case titleSymbol = "title_symbol"
        case buttonTitle = "button_title"
        case buttonSymbol = "button_symbol"
    }
}

// MARK: - Navigation Type
enum NavigationType: String, Codable {
    case push
    case modal
    case fullScreen = "full_screen"
}

