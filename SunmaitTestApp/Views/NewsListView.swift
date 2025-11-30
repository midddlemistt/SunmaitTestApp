import SwiftUI

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    
    // Navigation states
    @State private var navigationPath = NavigationPath()
    @State private var modalBlock: NavigationBlock?
    @State private var fullScreenBlock: NavigationBlock?
    @State private var selectedArticle: Article?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color("AppBeige").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Content
                    contentView
                }
            }
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isOffline {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 12, weight: .medium))
                            Text("Offline")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    }
                }
            }
            .navigationDestination(for: NavigationBlock.self) { block in
                PushNavigationView(block: block)
            }
        }
        .sheet(item: $modalBlock) { block in
            ModalNavigationView(block: block)
        }
        .fullScreenCover(item: $fullScreenBlock) { block in
            FullScreenNavigationView(block: block)
        }
        .fullScreenCover(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .alert("Do you want to block?", isPresented: $viewModel.showBlockAlert) {
            Button("Block", role: .destructive) {
                viewModel.confirmBlock()
            }
            Button("Cancel", role: .cancel) {
                viewModel.articleToBlock = nil
            }
        } message: {
            Text("Confirm to hide this news source")
        }
        .alert("Do you want to unblock?", isPresented: $viewModel.showUnblockAlert) {
            Button("Unblock", role: .destructive) {
                viewModel.confirmUnblock()
            }
            Button("Cancel", role: .cancel) {
                viewModel.articleToUnblock = nil
            }
        } message: {
            Text("Confirm to unblock this news source")
        }
        .alert(viewModel.errorMessage ?? "Something Went Wrong", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        Picker("Tab", selection: $viewModel.selectedTab) {
            ForEach(NewsTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            LoadingView()
            
        case .loaded, .empty, .offline:
            if viewModel.isEmpty {
                EmptyStateView(
                    icon: viewModel.emptyStateIcon,
                    title: viewModel.emptyStateTitle,
                    subtitle: viewModel.emptyStateSubtitle,
                    showRefreshButton: viewModel.selectedTab == .all,
                    onRefresh: {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            } else {
                articlesList
            }
            
        case .error:
            EmptyStateView(
                icon: "exclamationmark.circle.fill",
                title: "Something Went Wrong",
                subtitle: viewModel.errorMessage,
                showRefreshButton: true,
                onRefresh: {
                    Task {
                        await viewModel.refresh()
                    }
                }
            )
        }
    }
    
    // MARK: - Articles List
    
    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.listItems, id: \.id) { item in
                    listItemView(for: item)
                        .id(item.id) // Stable identity for smooth scrolling
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                        }
                }
                
                // Loading more indicator
                if viewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("AppGrey")))
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - List Item View
    
    @ViewBuilder
    private func listItemView(for item: ListItem) -> some View {
        switch item {
        case .article(let article):
            articleRow(for: article)
            
        case .navigationBlock(let block):
            NavigationBlockView(block: block) {
                handleNavigationBlockTap(block)
            }
        }
    }
    
    private func articleRow(for article: Article) -> some View {
        ArticleRowView(
            article: article,
            isFavorite: viewModel.isFavorite(article),
            isInBlockedTab: viewModel.selectedTab == .blocked,
            onTap: {
                openArticle(article)
            },
            onFavoriteToggle: {
                viewModel.toggleFavorite(article)
            },
            onBlock: {
                viewModel.prepareToBlock(article)
            },
            onUnblock: {
                viewModel.prepareToUnblock(article)
            }
        )
    }
    
    // MARK: - Actions
    
    private func openArticle(_ article: Article) {
        selectedArticle = article
    }
    
    private func handleNavigationBlockTap(_ block: NavigationBlock) {
        switch block.navigation {
        case .push:
            navigationPath.append(block)
        case .modal:
            modalBlock = block
        case .fullScreen:
            fullScreenBlock = block
        }
    }
}

#Preview {
    NewsListView()
}
