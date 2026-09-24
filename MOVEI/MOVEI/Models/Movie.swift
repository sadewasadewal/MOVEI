//
//  Movie.swift
//  MOVEI
//

import SwiftUI

public enum MovieStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case published
    case archived

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .draft: return "Draft"
        case .published: return "Published"
        case .archived: return "Archived"
        }
    }
}

public struct Movie: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var slug: String
    public var tagline: String
    public var description: String
    public var genre: String
    public var genres: [String]
    public var runtime: String
    public var runtimeMinutes: Int
    public var rating: String
    public var posterURL: String
    public var backdropURL: String
    public var logoURL: String?
    public var trailerURL: String?
    public var status: MovieStatus
    public var releaseDate: Date

    // Computed accent color based on slug/genres for backwards compatibility with UI
    public var accent: Color {
        switch slug {
        case "wicked": return .green
        case "brand-new-day": return .red
        case "oppenheimer": return .orange
        case "interstellar": return .cyan
        case "barbie": return .pink
        case "the-batman": return .yellow
        default: return AppTheme.lime
        }
    }

    public var resolvedPosterURL: URL? {
        ImageURLResolver.resolve(posterURL, fallback: backdropURL, baseURL: MovieService.shared.activeBaseURL)
    }

    public var resolvedBackdropURL: URL? {
        ImageURLResolver.resolve(backdropURL, fallback: posterURL, baseURL: MovieService.shared.activeBaseURL)
    }

    public var allPosterCandidateURLs: [URL] {
        ImageURLResolver.resolveAllCandidates(posterURL, fallback: backdropURL)
    }

    public var allBackdropCandidateURLs: [URL] {
        ImageURLResolver.resolveAllCandidates(backdropURL, fallback: posterURL)
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        slug: String,
        tagline: String,
        description: String = "",
        genres: [String],
        runtimeMinutes: Int,
        rating: String = "8.0",
        posterURL: String,
        backdropURL: String,
        logoURL: String? = nil,
        trailerURL: String? = nil,
        status: MovieStatus = .published,
        releaseDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.tagline = tagline
        self.description = description
        self.genres = genres
        self.genre = genres.joined(separator: " · ")
        self.runtimeMinutes = runtimeMinutes
        let hours = runtimeMinutes / 60
        let mins = runtimeMinutes % 60
        self.runtime = "\(hours)h \(mins)m"
        self.rating = rating
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.logoURL = logoURL
        self.trailerURL = trailerURL
        self.status = status
        self.releaseDate = releaseDate
    }

    enum CodingKeys: String, CodingKey {
        case id, title, slug, tagline, description, genre, genres
        case runtime, runtimeMinutes
        case rating, posterURL, backdropURL, logoURL, trailerURL
        case status, releaseDate
    }

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(slug, forKey: .slug)
        try container.encode(tagline, forKey: .tagline)
        try container.encode(description, forKey: .description)
        try container.encode(genre, forKey: .genre)
        try container.encode(genres, forKey: .genres)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(runtimeMinutes, forKey: .runtimeMinutes)
        try container.encode(rating, forKey: .rating)
        try container.encode(posterURL, forKey: .posterURL)
        try container.encode(backdropURL, forKey: .backdropURL)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
        try container.encodeIfPresent(trailerURL, forKey: .trailerURL)
        try container.encode(status, forKey: .status)
        try container.encode(releaseDate, forKey: .releaseDate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        func strVal(_ keys: String...) -> String? {
            for k in keys {
                if let key = DynamicCodingKey(stringValue: k),
                   let val = try? container.decodeIfPresent(String.self, forKey: key) {
                    return val
                }
            }
            return nil
        }

        let parsedTitle = strVal("title") ?? "Untitled"
        self.title = parsedTitle
        self.id = strVal("id") ?? UUID().uuidString
        self.slug = strVal("slug") ?? parsedTitle.lowercased().replacingOccurrences(of: " ", with: "-")
        self.tagline = strVal("tagline") ?? ""
        self.description = strVal("description") ?? ""

        var parsedGenres: [String] = []
        if let gKey = DynamicCodingKey(stringValue: "genres"),
           let gList = try? container.decodeIfPresent([String].self, forKey: gKey) {
            parsedGenres = gList
        }
        self.genres = parsedGenres
        self.genre = strVal("genre") ?? (parsedGenres.isEmpty ? "Cinema" : parsedGenres.joined(separator: " · "))

        var rt = 120
        for k in ["runtime_minutes", "runtimeMinutes"] {
            if let key = DynamicCodingKey(stringValue: k),
               let val = try? container.decodeIfPresent(Int.self, forKey: key) {
                rt = val
                break
            }
        }
        self.runtimeMinutes = rt
        let hours = rt / 60
        let mins = rt % 60
        self.runtime = "\(hours)h \(mins)m"

        var rVal = "8.0"
        if let key = DynamicCodingKey(stringValue: "rating") {
            if let s = try? container.decodeIfPresent(String.self, forKey: key) {
                rVal = s
            } else if let d = try? container.decodeIfPresent(Double.self, forKey: key) {
                rVal = String(format: "%.1f", d)
            }
        }
        self.rating = rVal

        self.posterURL = strVal("poster_url", "posterURL") ?? "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600"
        self.backdropURL = strVal("backdrop_url", "backdropURL") ?? "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1920"
        self.logoURL = strVal("logo_url", "logoURL")
        self.trailerURL = strVal("trailer_url", "trailerURL")

        if let rawStatus = strVal("status") {
            self.status = MovieStatus(rawValue: rawStatus.lowercased()) ?? .published
        } else {
            self.status = .published
        }

        var rDate = Date()
        for k in ["release_date", "releaseDate"] {
            if let key = DynamicCodingKey(stringValue: k) {
                if let d = try? container.decodeIfPresent(Date.self, forKey: key) {
                    rDate = d
                    break
                } else if let str = try? container.decodeIfPresent(String.self, forKey: key) {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withFullDate]
                    if let parsed = formatter.date(from: str) {
                        rDate = parsed
                        break
                    }
                }
            }
        }
        self.releaseDate = rDate
    }
}
