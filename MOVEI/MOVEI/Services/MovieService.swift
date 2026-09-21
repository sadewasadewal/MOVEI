//
//  MovieService.swift
//  MOVEI
//

import SwiftUI
import Combine

@MainActor
public final class MovieService: ObservableObject {
    public static let shared = MovieService()

    @Published public var movies: [Movie] = []
    @Published public var isLoading: Bool = false
    @Published public var syncStatusMessage: String = "Ready"
    @Published public var lastSyncDate: Date? = nil
    @Published public var activeEndpoint: String = "Auto-detecting..."
    @Published public var customServerHost: String {
        didSet {
            UserDefaults.standard.set(customServerHost, forKey: "movei_custom_server_host")
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var pollTimer: Timer?

    public var publishedMovies: [Movie] {
        movies.filter { $0.status == .published }
    }

    public var activeBaseURL: String {
        if let url = URL(string: activeEndpoint), let host = url.host {
            let portStr = url.port != nil ? ":\(url.port!)" : ""
            return "http://\(host)\(portStr)"
        }
        let saved = customServerHost.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty {
            return saved.hasPrefix("http") ? saved : "http://\(saved)"
        }
        return "http://192.168.1.12:3000"
    }

    private init() {
        let savedHost = UserDefaults.standard.string(forKey: "movei_custom_server_host")
        self.customServerHost = savedHost ?? "192.168.1.12:3000"

        // Flush old legacy caches to ensure clean start with exactly the 6 movies
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies")
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies_v2")
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies_v3")

        // 1. Try restoring from persistent local cache v4
        if !loadFromCache() {
            // 2. Load fresh default catalog containing the 6 requested movies
            loadDefaultMovies()
        }

        // 3. Initial sync attempt
        Task {
            await fetchMoviesFromBackend()
        }

        // 4. Auto-refresh when app comes to foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchMoviesFromBackend()
                }
            }
            .store(in: &cancellables)

        // 5. Periodic polling (every 5 seconds) while app is open for live studio updates
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }

    public func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Silent background check
                await self.fetchMoviesFromBackend(silent: true)
            }
        }
    }

    @discardableResult
    public func fetchMoviesFromBackend(silent: Bool = false) async -> Bool {
        if !silent {
            isLoading = true
        }
        defer {
            if !silent {
                isLoading = false
            }
        }

        // Check local disk direct file access (works in Simulator / macOS debug environment)
        let localDiskPath = "/Users/sandew/Swifts/MOVEI/web/movei-web/data/movies.json"
        if FileManager.default.fileExists(atPath: localDiskPath),
           let diskData = try? Data(contentsOf: URL(fileURLWithPath: localDiskPath)),
           let decoded = try? JSONDecoder().decode([Movie].self, from: diskData),
           !decoded.isEmpty {
            self.movies = decoded
            self.saveToCache(diskData)
            self.activeEndpoint = "Local Studio Disk"
            self.syncStatusMessage = "Loaded \(decoded.count) movies from Admin disk"
            self.lastSyncDate = Date()
            return true
        }

        // Assemble candidate endpoints in priority order
        var candidateEndpoints: [String] = []

        let trimmedHost = customServerHost.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedHost.isEmpty {
            let hostWithScheme = trimmedHost.hasPrefix("http") ? trimmedHost : "http://\(trimmedHost)"
            let apiPath = hostWithScheme.hasSuffix("/api/movies") ? hostWithScheme : "\(hostWithScheme)/api/movies"
            candidateEndpoints.append(apiPath)
        }

        // Known Bonjour / LAN / loopback addresses
        candidateEndpoints.append("http://192.168.1.12:3000/api/movies")
        candidateEndpoints.append("http://Sandews-MacBook-Air.local:3000/api/movies")
        candidateEndpoints.append("http://172.20.10.4:3000/api/movies")
        candidateEndpoints.append("http://localhost:3000/api/movies")
        candidateEndpoints.append("http://127.0.0.1:3000/api/movies")

        // Deduplicate endpoints
        var seen = Set<String>()
        let uniqueEndpoints = candidateEndpoints.filter { seen.insert($0).inserted }

        for ep in uniqueEndpoints {
            guard let url = URL(string: ep) else { continue }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 2.5
                request.cachePolicy = .reloadIgnoringLocalCacheData
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    let decoded = try JSONDecoder().decode([Movie].self, from: data)
                    if !decoded.isEmpty {
                        self.movies = decoded
                        self.saveToCache(data)
                        self.activeEndpoint = ep
                        self.syncStatusMessage = "Synced \(decoded.count) movies via \(url.host ?? "Admin")"
                        self.lastSyncDate = Date()
                        print("🛰️ [MovieService] Successfully synced \(decoded.count) movies from \(ep)")
                        return true
                    }
                }
            } catch {
                // Silently try next candidate
            }
        }

        if !silent {
            self.syncStatusMessage = "Using offline cache (\(self.movies.count) movies)"
        }
        return false
    }

    private func saveToCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: "movei_cached_movies_v3")
    }

    private func loadFromCache() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "movei_cached_movies_v4"),
              let decoded = try? JSONDecoder().decode([Movie].self, from: data),
              !decoded.isEmpty else {
            return false
        }
        self.movies = decoded
        self.syncStatusMessage = "Restored \(decoded.count) movies from cache"
        return true
    }

    public func clearCacheAndReload() {
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies")
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies_v2")
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies_v3")
        UserDefaults.standard.removeObject(forKey: "movei_cached_movies_v4")
        URLCache.shared.removeAllCachedResponses()
        loadDefaultMovies()
        Task {
            await fetchMoviesFromBackend()
        }
    }

    public func loadDefaultMovies() {
        self.movies = [
            Movie(
                id: "m-wicked",
                title: "Wicked",
                slug: "wicked",
                tagline: "Everyone deserves the chance to fly.",
                description: "Elphaba, an ostracized but fiery girl and Glinda, a bubbly popular aristocrat, forge an improbable bond in the magical land of Oz, before destiny pulls them into the legendary conflict.",
                genres: ["Fantasy", "Musical", "Adventure"],
                runtimeMinutes: 160,
                rating: "8.5",
                posterURL: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&h=900&q=80",
                backdropURL: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=1920&h=1080&q=80",
                status: .published
            ),
            Movie(
                id: "m-inception",
                title: "Inception",
                slug: "inception",
                tagline: "Your mind is the scene of the crime.",
                description: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O., but his tragic past may doom the project and his team to disaster.",
                genres: ["Action", "Sci-Fi", "Adventure"],
                runtimeMinutes: 148,
                rating: "8.8",
                posterURL: "https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=600&h=900&q=80",
                backdropURL: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1920&h=1080&q=80",
                status: .published
            ),
            Movie(
                id: "m-oppenheimer",
                title: "Oppenheimer",
                slug: "oppenheimer",
                tagline: "The world forever changes.",
                description: "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.",
                genres: ["Biography", "Drama", "History"],
                runtimeMinutes: 180,
                rating: "8.9",
                posterURL: "https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=600&h=900&q=80",
                backdropURL: "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?auto=format&fit=crop&w=1920&h=1080&q=80",
                status: .published
            ),
            Movie(
                id: "m-interstellar",
                title: "Interstellar",
                slug: "interstellar",
                tagline: "Mankind was born on Earth. It was never meant to die here.",
                description: "When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot, Joseph Cooper, is tasked to pilot a spacecraft, along with a team of researchers, to find a new planet for humans.",
                genres: ["Adventure", "Drama", "Sci-Fi"],
                runtimeMinutes: 169,
                rating: "8.7",
                posterURL: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&h=900&q=80",
                backdropURL: "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1920&h=1080&q=80",
                status: .published
            ),
            Movie(
                id: "m-spiderman",
                title: "Spider-Man: Brand New Day",
                slug: "spider-man--brand-new-day",
                tagline: "Even if no one remembers me, I'll keep protecting.",
                description: "A forgotten Peter Parker lives alone as a full-time Spider-Man until mounting pressure triggers a dangerous change and a powerful new enemy emerges.",
                genres: ["Action", "Sci-Fi", "Superhero"],
                runtimeMinutes: 145,
                rating: "8.8",
                posterURL: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=600&q=90",
                backdropURL: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=1800&q=90",
                status: .published
            ),
            Movie(
                id: "m-pak",
                title: "PAK",
                slug: "pak",
                tagline: "A new cinematic force begins.",
                description: "An intense thrilling odyssey of resilience, courage and unyielding redemption.",
                genres: ["Action", "Thriller"],
                runtimeMinutes: 135,
                rating: "8.5",
                posterURL: "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=600&q=80",
                backdropURL: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1920&h=1080&q=80",
                status: .published
            )
        ]
    }

    public func addOrUpdate(movie: Movie) {
        if let idx = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[idx] = movie
        } else {
            movies.append(movie)
        }
    }

    public func canPublish(movie: Movie) -> (canPublish: Bool, reasons: [String]) {
        var reasons: [String] = []
        if movie.title.trimmingCharacters(in: .whitespaces).isEmpty {
            reasons.append("Title is required")
        }
        if movie.description.trimmingCharacters(in: .whitespaces).isEmpty {
            reasons.append("Description is required")
        }
        if movie.posterURL.trimmingCharacters(in: .whitespaces).isEmpty {
            reasons.append("Poster artwork is required")
        }
        if movie.backdropURL.trimmingCharacters(in: .whitespaces).isEmpty {
            reasons.append("Backdrop artwork is required")
        }
        if movie.runtimeMinutes <= 0 {
            reasons.append("Valid runtime is required")
        }
        if movie.genres.isEmpty {
            reasons.append("At least one genre is required")
        }
        return (reasons.isEmpty, reasons)
    }

    public func publish(movieID: String) -> Bool {
        guard let idx = movies.firstIndex(where: { $0.id == movieID }) else { return false }
        let (valid, _) = canPublish(movie: movies[idx])
        if valid {
            movies[idx].status = .published
            return true
        }
        return false
    }

    public func archive(movieID: String) {
        if let idx = movies.firstIndex(where: { $0.id == movieID }) {
            movies[idx].status = .archived
        }
    }
}
