import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showRefreshButton: Bool
    let onRefresh: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        showRefreshButton: Bool = false,
        onRefresh: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showRefreshButton = showRefreshButton
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.appBlue)
            
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.appBlack)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.appGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if showRefreshButton, let onRefresh = onRefresh {
                Button(action: onRefresh) {
                    HStack(spacing: 8) {
                        Text("Refresh")
                            .font(.system(size: 17, weight: .bold))
                        
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(.appWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.appBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "heart.circle.fill",
            title: "No Favorite News",
            subtitle: "Add articles to favorites to see them here"
        )
        
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            subtitle: "Check your connection and try again",
            showRefreshButton: true,
            onRefresh: {}
        )
    }
    .background(.appBeige)
}
