import SwiftUI

// MARK: - Image Cache Service
final class ImageCacheService {
    static let shared = ImageCacheService()
    
    // In-memory cache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache using URLCache
    private let urlCache: URLCache
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 100 // Max 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Configure URL cache for disk persistence
        // 50 MB memory, 200 MB disk
        urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "image_cache"
        )
    }
    
    // MARK: - Public Methods
    
    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        let request = URLRequest(url: url)
        if let cachedResponse = urlCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            // Store in memory cache for faster access next time
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    func store(_ image: UIImage, for url: URL, data: Data? = nil) {
        let key = url.absoluteString as NSString
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key)
        
        // Store in disk cache
        if let imageData = data ?? image.jpegData(compressionQuality: 0.8) {
            let request = URLRequest(url: url)
            let response = URLResponse(
                url: url,
                mimeType: "image/jpeg",
                expectedContentLength: imageData.count,
                textEncodingName: nil
            )
            let cachedResponse = CachedURLResponse(response: response, data: imageData)
            urlCache.storeCachedResponse(cachedResponse, for: request)
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        urlCache.removeAllCachedResponses()
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let url = url, !isLoading else { return }
        
        // Check cache first
        if let cachedImage = ImageCacheService.shared.image(for: url) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                // Store in cache
                ImageCacheService.shared.store(downloadedImage, for: url, data: data)
                
                await MainActor.run {
                    self.image = downloadedImage
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        self.placeholder = { ProgressView() }
    }
}

