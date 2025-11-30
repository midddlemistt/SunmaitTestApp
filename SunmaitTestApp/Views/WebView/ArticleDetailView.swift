import SwiftUI
@preconcurrency import WebKit

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var progress: Double = 0
    @State private var webView: WKWebView?
    @State private var isInitialLoad = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBeige").ignoresSafeArea()
                
                if let url = article.articleURL {
                    // WebView
                    ArticleWebView(
                        url: url,
                        isLoading: $isLoading,
                        canGoBack: $canGoBack,
                        progress: $progress,
                        webView: $webView
                    )
                    .ignoresSafeArea(edges: .bottom)
                    
                    // Initial load overlay with blur
                    if isInitialLoad && isLoading {
                        initialLoadOverlay
                    }
                } else {
                    errorView
                }
            }
            .navigationTitle(article.sectionName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                // Progress bar under navigation bar
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(article.sectionName)
                            .font(.headline)
                        
                        // Progress bar (Safari style)
                        if isLoading && !isInitialLoad {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color("AppGrey").opacity(0.2))
                                        .frame(height: 2)
                                    
                                    Rectangle()
                                        .fill(Color("AppBlue"))
                                        .frame(width: geometry.size.width * progress, height: 2)
                                        .animation(.linear(duration: 0.1), value: progress)
                                }
                            }
                            .frame(height: 2)
                            .padding(.top, 4)
                        }
                    }
                }
                
                // Left: Close button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color("AppBlue"))
                    }
                }
                
                // Right: Navigation and Share
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Back button (when can go back)
                    if canGoBack {
                        Button {
                            webView?.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color("AppBlue"))
                        }
                    }
                    
                    // Refresh / Stop
                    Button {
                        if isLoading {
                            webView?.stopLoading()
                        } else {
                            webView?.reload()
                        }
                    } label: {
                        Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color("AppBlue"))
                    }
                    
                    // Share
                    ShareLink(item: article.webUrl) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color("AppBlue"))
                    }
                }
            }
            .onChange(of: isLoading) { _, newValue in
                if !newValue && isInitialLoad {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isInitialLoad = false
                    }
                }
            }
        }
    }
    
    // MARK: - Initial Load Overlay
    
    private var initialLoadOverlay: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Center loader
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AppBlue")))
                    .scaleEffect(1.5)
                
                Text("Loading article...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("AppGrey"))
                
                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("AppBlue"))
                    .monospacedDigit()
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("AppWhite"))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AppGrey"))
            
            Text("Invalid article URL")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color("AppGrey"))
        }
    }
}

#Preview {
    ArticleDetailView(
        article: Article(
            id: "preview",
            type: "article",
            sectionId: "technology",
            sectionName: "Technology",
            webPublicationDate: "2024-01-15T10:30:00Z",
            webTitle: "Sample Article Title for Preview",
            webUrl: "https://www.theguardian.com",
            apiUrl: "https://api.theguardian.com",
            isHosted: false,
            pillarId: nil,
            pillarName: nil,
            fields: nil
        )
    )
}
