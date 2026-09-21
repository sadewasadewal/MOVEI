//
//  RemoteImageLoader.swift
//  MOVEI
//

import SwiftUI
import UIKit

public enum ImageURLResolver {
    public static func resolve(_ raw: String, fallback: String? = nil, baseURL: String) -> URL? {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty, let fb = fallback {
            clean = fb.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !clean.isEmpty else { return nil }

        let fullString: String
        if clean.contains("/uploads/") {
            if let uploadRange = clean.range(of: "/uploads/") {
                let suffix = String(clean[uploadRange.lowerBound...])
                fullString = "\(baseURL)\(suffix)"
            } else {
                fullString = clean
            }
        } else if clean.hasPrefix("/") {
            fullString = "\(baseURL)\(clean)"
        } else {
            fullString = clean
        }

        // Try direct parse first
        if let direct = URL(string: fullString) {
            return direct
        }

        // Encode characters including spaces and unicode
        var allowed = CharacterSet.urlPathAllowed
        allowed.formUnion(.urlQueryAllowed)
        allowed.formUnion(.urlFragmentAllowed)
        allowed.formUnion(CharacterSet(charactersIn: ":/"))

        if let encoded = fullString.addingPercentEncoding(withAllowedCharacters: allowed),
           let url = URL(string: encoded) {
            return url
        }

        return nil
    }
}

public final class RemoteImageCache: @unchecked Sendable {
    public static let shared = RemoteImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 150
        cache.totalCostLimit = 1024 * 1024 * 80 // 80 MB
    }

    public func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    public func set(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

public actor RemoteImageLoader {
    public static let shared = RemoteImageLoader()

    private init() {}

    public func loadImage(from candidateURLs: [URL]) async -> UIImage? {
        guard !candidateURLs.isEmpty else { return nil }

        // 1. Check in-memory cache first for any candidate
        for url in candidateURLs {
            if let cached = RemoteImageCache.shared.image(for: url.absoluteString) {
                return cached
            }
        }

        // 2. Try fetching each candidate with cancellation retry
        for url in candidateURLs {
            if let img = await fetchWithRetry(url: url, retries: 2) {
                RemoteImageCache.shared.set(img, for: url.absoluteString)
                return img
            }
        }

        return nil
    }

    private func fetchWithRetry(url: URL, retries: Int) async -> UIImage? {
        for attempt in 0...retries {
            do {
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12.0)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    if let image = UIImage(data: data) {
                        return image
                    }
                }
            } catch {
                if let urlErr = error as? URLError, urlErr.code == .cancelled {
                    // Sheet dismissal or modal transition in progress; back off and retry
                    if attempt < retries {
                        try? await Task.sleep(nanoseconds: 180_000_000)
                        continue
                    }
                }
            }
        }
        return nil
    }
}

public struct RobustAsyncImage<Content: View, Placeholder: View>: View {
    public let candidateURLs: [URL]
    public let content: (Image) -> Content
    public let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var isLoaded = false

    public init(
        candidateURLs: [URL],
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.candidateURLs = candidateURLs
        self.content = content
        self.placeholder = placeholder

        // Check if pre-cached
        for url in candidateURLs {
            if let cached = RemoteImageCache.shared.image(for: url.absoluteString) {
                _uiImage = State(initialValue: cached)
                _isLoaded = State(initialValue: true)
                break
            }
        }
    }

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(candidateURLs: [url].compactMap { $0 }, content: content, placeholder: placeholder)
    }

    public var body: some View {
        Group {
            if let img = uiImage {
                content(Image(uiImage: img))
            } else {
                placeholder()
            }
        }
        .task(id: candidateURLs.map(\.absoluteString).joined(separator: "|")) {
            if uiImage == nil && !candidateURLs.isEmpty {
                let img = await RemoteImageLoader.shared.loadImage(from: candidateURLs)
                if let img {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.uiImage = img
                        self.isLoaded = true
                    }
                }
            }
        }
    }
}
