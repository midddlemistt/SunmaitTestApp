import SwiftUI
import Combine
@preconcurrency import WebKit

// MARK: - Article WebView Representable

struct ArticleWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var progress: Double
    @Binding var webView: WKWebView?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Современный User Agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        
        // Фон под цвет приложения
        webView.backgroundColor = UIColor(named: "AppBeige")
        webView.scrollView.backgroundColor = UIColor(named: "AppBeige")
        
        // Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(named: "AppBlue")
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        webView.scrollView.bounces = true
        context.coordinator.refreshControl = refreshControl
        
        // Сохраняем ссылку для управления навигацией
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        // Подписка на изменение прогресса
        context.coordinator.setupProgressObserver(for: webView)
        
        // Загружаем URL
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Обновления не требуются
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ArticleWebView
        private var progressObserver: AnyCancellable?
        weak var refreshControl: UIRefreshControl?
        
        init(_ parent: ArticleWebView) {
            self.parent = parent
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            parent.webView?.reload()
        }
        
        func setupProgressObserver(for webView: WKWebView) {
            progressObserver = webView.publisher(for: \.estimatedProgress)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progress in
                    self?.parent.progress = progress
                }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.progress = 0
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.progress = 1.0
            refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let scheme = url.scheme?.lowercased()
                
                // Внешние схемы (tel:, mailto:, и т.д.) открываем в системе
                if let scheme = scheme, scheme != "http", scheme != "https", scheme != "about" {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
                
                // Popup (target="_blank") открываем в этом же WebView
                if navigationAction.targetFrame == nil {
                    webView.load(URLRequest(url: url))
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}
