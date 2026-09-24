//
//  RemoteImageLoader.swift
//  MOVEI
//

import SwiftUI
import UIKit

public enum ImageURLResolver {
    public static func resolveAllCandidates(_ raw: String, fallback: String? = nil) -> [URL] {
        var results: [URL] = []
        var seen = Set<String>()

        func appendIfNew(_ url: URL?) {
            guard let url = url else { return }
            let s = url.absoluteString
            if !seen.contains(s) {
                seen.insert(s)
                results.append(url)
            }
        }

        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. If it contains an uploads path (e.g. /uploads/posters/...)
        if clean.contains("/uploads/") {
            let suffix: String
            if let uploadRange = clean.range(of: "/uploads/") {
                suffix = String(clean[uploadRange.lowerBound...])
            } else {
                suffix = clean
            }

            // Check if local file exists on disk (macOS / Simulator direct access)
            let localDiskPrefix = "/Users/sandew/Swifts/MOVEI/web/movei-web/public"
            let localPath = "\(localDiskPrefix)\(suffix)"
            if FileManager.default.fileExists(atPath: localPath) {
                appendIfNew(URL(fileURLWithPath: localPath))
            }

            // Generate candidate network hosts in order of reachability (Cloud tunnel first for mobile data)
            let activeBase = MovieService.shared.activeBaseURL
            let candidateBases: [String] = [
                activeBase,
                "https://validation-announced-clay-consisting.trycloudflare.com",
                "http://192.168.1.12:3000",
                "http://Sandews-MacBook-Air.local:3000",
                "http://127.0.0.1:3000",
                "http://localhost:3000"
            ]

            for base in candidateBases {
                let full = "\(base)\(suffix)"
                if let u = URL(string: full) {
                    appendIfNew(u)
                }
            }
        } else if clean.hasPrefix("http://") || clean.hasPrefix("https://") {
            // 2. Direct external web URL (e.g. Unsplash, TMDB, Supabase, Cloudflare)
            if let direct = URL(string: clean) {
                if !clean.contains("localhost") && !clean.contains("127.0.0.1") {
                    appendIfNew(direct)
                }
            }
        } else if clean.hasPrefix("/") {
            let activeBase = MovieService.shared.activeBaseURL
            let candidateBases: [String] = [
                activeBase,
                "https://validation-announced-clay-consisting.trycloudflare.com",
                "http://192.168.1.12:3000",
                "http://Sandews-MacBook-Air.local:3000",
                "http://127.0.0.1:3000",
                "http://localhost:3000"
            ]
            for base in candidateBases {
                if let u = URL(string: "\(base)\(clean)") {
                    appendIfNew(u)
                }
            }
        } else if let direct = URL(string: clean) {
            appendIfNew(direct)
        }

        // 3. Fallback URL candidates
        if let fb = fallback, !fb.isEmpty && fb != raw {
            let fbCandidates = resolveAllCandidates(fb, fallback: nil)
            for fbUrl in fbCandidates {
                appendIfNew(fbUrl)
            }
        }

        return results
    }

    public static func resolve(_ raw: String, fallback: String? = nil, baseURL: String) -> URL? {
        let candidates = resolveAllCandidates(raw, fallback: fallback)
        return candidates.first
    }
}

public final class RemoteDiskCache: @unchecked Sendable {
    public static let shared = RemoteDiskCache()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectory = cachesURL.appendingPathComponent("movei_posters", isDirectory: true)
        } else {
            cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("movei_posters", isDirectory: true)
        }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
        let hash = String(key.hashValue)
        let filename = "\(hash)_\(safeKey.suffix(32)).img"
        return cacheDirectory.appendingPathComponent(filename)
    }

    public func image(for key: String) -> UIImage? {
        let url = fileURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return nil }
        return img
    }

    public func set(_ image: UIImage, for key: String) {
        let url = fileURL(for: key)
        Task.detached(priority: .background) {
            if let data = image.jpegData(compressionQuality: 0.88) ?? image.pngData() {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

public final class RemoteImageCache: @unchecked Sendable {
    public static let shared = RemoteImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 120 // 120 MB
    }

    public func image(for key: String) -> UIImage? {
        // 1. Memory cache check
        if let memoryImg = cache.object(forKey: key as NSString) {
            return memoryImg
        }
        // 2. Persistent disk cache check
        if let diskImg = RemoteDiskCache.shared.image(for: key) {
            let cost = Int(diskImg.size.width * diskImg.size.height * 4)
            cache.setObject(diskImg, forKey: key as NSString, cost: cost)
            return diskImg
        }
        return nil
    }

    public func set(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        RemoteDiskCache.shared.set(image, for: key)
    }
}

public actor RemoteImageLoader {
    public static let shared = RemoteImageLoader()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 8.0
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 60 * 1024 * 1024, diskCapacity: 250 * 1024 * 1024)
        self.session = URLSession(configuration: config)
    }

    public func loadImage(from candidateURLs: [URL]) async -> UIImage? {
        guard !candidateURLs.isEmpty else { return nil }

        // 1. Check in-memory & disk cache first for any candidate
        for url in candidateURLs {
            if let cached = RemoteImageCache.shared.image(for: url.absoluteString) {
                return cached
            }
        }

        // 2. Check local file URLs immediately (0ms latency)
        for url in candidateURLs where url.isFileURL {
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                RemoteImageCache.shared.set(img, for: url.absoluteString)
                return img
            }
        }

        // 3. Race candidate network URLs concurrently
        let remoteURLs = candidateURLs.filter { !$0.isFileURL }
        if remoteURLs.isEmpty { return nil }

        return await withTaskGroup(of: (URL, UIImage)?.self) { group in
            for url in remoteURLs.prefix(5) {
                group.addTask {
                    if let img = await self.fetchSingle(url: url) {
                        return (url, img)
                    }
                    return nil
                }
            }

            for await result in group {
                if let (url, img) = result {
                    group.cancelAll()
                    RemoteImageCache.shared.set(img, for: url.absoluteString)
                    // Alias to other candidate keys for instant subsequent retrieval
                    for cUrl in candidateURLs {
                        RemoteImageCache.shared.set(img, for: cUrl.absoluteString)
                    }
                    return img
                }
            }
            return nil
        }
    }

    private func fetchSingle(url: URL) async -> UIImage? {
        do {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 3.5)
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                if let image = UIImage(data: data) {
                    return image
                }
            }
        } catch {
            // Silently fail to let other race candidate succeed
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

        // Check if pre-cached in memory or disk
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

