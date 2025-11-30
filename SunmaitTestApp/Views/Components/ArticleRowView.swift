import SwiftUI

struct ArticleRowView: View {
    let article: Article
    let isFavorite: Bool
    let isInBlockedTab: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    let onBlock: () -> Void
    let onUnblock: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Картинка на всю ширину (если есть)
            if article.thumbnailURL != nil {
                thumbnailView
            }
            
            // Заголовок + меню
            HStack(alignment: .top, spacing: 8) {
                Text(article.webTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.appBlack)
                    .lineLimit(4) // Больше строк для заголовка
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                menuButton
            }
            
            // Метаданные
            HStack(spacing: 4) {
                Text(article.sectionName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.appGrey)
                
                Circle()
                    .fill(.appGrey)
                    .frame(width: 4, height: 4)
                
                Text(article.formattedDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.appGrey)
            }
            
            // Кнопка "Read Article"
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Text("Read Article")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .foregroundStyle(.appBlue)
            .background(.appBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(12)
        .background(.appWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Menu Button
    
    private var menuButton: some View {
        Menu {
            if isInBlockedTab {
                Button(role: .destructive) {
                    onUnblock()
                } label: {
                    Label("Unblock", systemImage: "lock.open")
                }
            } else {
                Button {
                    onFavoriteToggle()
                } label: {
                    Label(
                        isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: isFavorite ? "heart.slash" : "heart"
                    )
                }
                
                Button(role: .destructive) {
                    onBlock()
                } label: {
                    Label("Block", systemImage: "nosign")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundStyle(.appGrey)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }
    
    // MARK: - Thumbnail View
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = article.thumbnailURL {
            CachedAsyncImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.appBeige)
                    .frame(height: 160)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appGrey))
                    }
            }
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.appBeige)
            .frame(height: 160)
            .overlay {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.appBlue)
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ArticleRowView(
                article: Article(
                    id: "test",
                    type: "article",
                    sectionId: "technology",
                    sectionName: "Technology",
                    webPublicationDate: "2024-04-17T10:00:00Z",
                    webTitle: "Street Art Festival Transforms City Walls Into Open-Air Gallery With Stunning Murals From International Artists",
                    webUrl: "https://example.com",
                    apiUrl: "https://api.example.com",
                    isHosted: false,
                    pillarId: nil,
                    pillarName: nil,
                    fields: ArticleFields(
                        thumbnail: "https://media.guim.co.uk/0d96b2832dba2e7c3c6068a6790423ae2c5ded37/247_0_4117_3294/500.jpg",
                        trailText: nil
                    )
                ),
                isFavorite: false,
                isInBlockedTab: false,
                onTap: {},
                onFavoriteToggle: {},
                onBlock: {},
                onUnblock: {}
            )
            
            ArticleRowView(
                article: Article(
                    id: "test2",
                    type: "article",
                    sectionId: "sport",
                    sectionName: "Football",
                    webPublicationDate: "2024-04-17T10:00:00Z",
                    webTitle: "West Ham United v Liverpool: Premier League – live updates and analysis",
                    webUrl: "https://example.com",
                    apiUrl: "https://api.example.com",
                    isHosted: false,
                    pillarId: nil,
                    pillarName: nil,
                    fields: nil
                ),
                isFavorite: true,
                isInBlockedTab: false,
                onTap: {},
                onFavoriteToggle: {},
                onBlock: {},
                onUnblock: {}
            )
        }
        .padding()
    }
    .background(.appBeige)
}
