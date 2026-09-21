//
//  MoviesView.swift
//  MOVEI
//

import SwiftUI

public struct MoviesView: View {
    @ObservedObject private var movieService = MovieService.shared
    public let onMovie: (Movie) -> Void
    @State private var search = ""

    public init(onMovie: @escaping (Movie) -> Void) {
        self.onMovie = onMovie
    }

    private var filteredMovies: [Movie] {
        if search.isEmpty { return movieService.publishedMovies }
        return movieService.publishedMovies.filter {
            $0.title.localizedCaseInsensitiveContains(search) || $0.genre.localizedCaseInsensitiveContains(search)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Header & Search
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Explore Movies")
                            .font(.system(size: 34, weight: .bold))

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppTheme.muted)
                            TextField("Search movies, genres...", text: $search)
                        }
                        .padding(14)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Spotlight
                    if let first = filteredMovies.first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FEATURED SPOTLIGHT")
                                .font(.caption.weight(.bold))
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.muted)
                                .padding(.horizontal, 20)

                            HeroCard(movie: first) { onMovie(first) }
                                .padding(.horizontal, 20)
                        }
                    }

                    // Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ALL MOVIES")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 18) {
                            ForEach(filteredMovies) { movie in
                                MovieGridCard(movie: movie)
                                    .onTapGesture { onMovie(movie) }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 110)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await movieService.fetchMoviesFromBackend()
            }
            .task {
                await movieService.fetchMoviesFromBackend()
            }
        }
    }
}

public struct HeroCard: View {
    public let movie: Movie
    public let action: () -> Void

    public init(movie: Movie, action: @escaping () -> Void) {
        self.movie = movie
        self.action = action
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            RobustAsyncImage(candidateURLs: [movie.resolvedBackdropURL, movie.resolvedPosterURL].compactMap { $0 }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppTheme.passBackground)
            }
            .frame(height: 240)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("\(movie.genre)  ·  \(movie.runtime)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Button(action: action) {
                    Label("Book tickets", systemImage: "ticket.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.lime)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
    }
}

public struct MovieGridCard: View {
    public let movie: Movie

    public init(movie: Movie) {
        self.movie = movie
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RobustAsyncImage(candidateURLs: [movie.resolvedPosterURL, movie.resolvedBackdropURL].compactMap { $0 }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppTheme.passBackground)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(.orange).font(.caption2)
                    Text(movie.rating).font(.caption2.weight(.semibold))
                    Text("·").foregroundStyle(AppTheme.muted)
                    Text(movie.runtime).font(.caption2).foregroundStyle(AppTheme.muted)
                }
            }
        }
    }
}
