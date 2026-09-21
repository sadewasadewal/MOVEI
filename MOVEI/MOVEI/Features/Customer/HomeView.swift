//
//  HomeView.swift
//  MOVEI
//

import SwiftUI

public struct HomeView: View {
    @ObservedObject private var movieService = MovieService.shared
    public let onBook: (Movie) -> Void
    public let onDetails: (Movie) -> Void
    public let onTicket: (Ticket) -> Void

    @State private var selectedMovieIndex = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isUserInteracting = false
    @State private var autoScrollTimer: Timer?

    public init(
        onBook: @escaping (Movie) -> Void,
        onDetails: @escaping (Movie) -> Void,
        onTicket: @escaping (Ticket) -> Void
    ) {
        self.onBook = onBook
        self.onDetails = onDetails
        self.onTicket = onTicket
    }

    public var body: some View {
        let movies = movieService.publishedMovies

        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Feature Carousel extending all the way to top of screen
                    if !movies.isEmpty {
                        ZStack(alignment: .top) {
                            // Full-bleed Poster Carousel
                            GeometryReader { proxy in
                                let width = proxy.size.width
                                let height = proxy.size.height

                                HStack(spacing: 0) {
                                    ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                                        HomeHeroSlide(
                                            movie: movie,
                                            width: width,
                                            height: height,
                                            onBook: { onBook(movie) },
                                            onDetails: { onDetails(movie) }
                                        )
                                    }
                                }
                                .frame(width: width * CGFloat(max(movies.count, 1)), alignment: .leading)
                                .offset(x: -CGFloat(selectedMovieIndex) * width + dragOffset)
                                .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.85), value: selectedMovieIndex)
                                .gesture(
                                    DragGesture(minimumDistance: 10)
                                        .updating($dragOffset) { value, state, _ in
                                            if abs(value.translation.width) > abs(value.translation.height) {
                                                state = value.translation.width
                                            }
                                        }
                                        .onChanged { _ in
                                            isUserInteracting = true
                                        }
                                        .onEnded { value in
                                            let threshold = width * 0.15
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                if value.translation.width < -threshold {
                                                    selectedMovieIndex = (selectedMovieIndex + 1) % movies.count
                                                } else if value.translation.width > threshold {
                                                    selectedMovieIndex = selectedMovieIndex == 0 ? (movies.count - 1) : (selectedMovieIndex - 1)
                                                }
                                            }
                                            // Resume auto-scroll after a short delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                                isUserInteracting = false
                                            }
                                        }
                                )
                            }
                            .frame(height: 580)

                            // Top Black Shade Gradient directly over the poster artwork
                            LinearGradient(
                                stops: [
                                    .init(color: Color.black.opacity(0.88), location: 0.0),
                                    .init(color: Color.black.opacity(0.55), location: 0.35),
                                    .init(color: Color.black.opacity(0.2), location: 0.72),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 165)
                            .allowsHitTesting(false)

                            // "Store" title and User icon rendered directly ON the poster
                            HStack(alignment: .center) {
                                Text("Store")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.white)

                                Spacer()

                                // Profile Avatar Icon sitting on the poster
                                Button {
                                    Task {
                                        await movieService.fetchMoviesFromBackend()
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.18))
                                            .frame(width: 36, height: 36)
                                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))

                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 56) // Positions below Dynamic Island / status bar
                        }
                        .frame(height: 580)

                        // Carousel Indicator Dots (below action buttons)
                        if movies.count > 1 {
                            HStack(spacing: 6) {
                                ForEach(0..<movies.count, id: \.self) { idx in
                                    Capsule()
                                        .fill(idx == selectedMovieIndex ? Color.white : Color.white.opacity(0.32))
                                        .frame(width: idx == selectedMovieIndex ? 22 : 6, height: 5)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedMovieIndex)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                        }
                    }

                    // Top Movies Chart Section (One row below the home page poster)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Text("Top Movies Chart")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.45))

                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 11) {
                                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                                    TopChartMovieCard(
                                        rank: index + 1,
                                        movie: movie,
                                        onTap: { onDetails(movie) },
                                        onBook: { onBook(movie) }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .ignoresSafeArea(edges: .top) // Fills poster completely to the very top edge of the screen!

            // Bottom blur overlay: softly blurs the bottom of cards until user scrolls up
            ZStack {
                // Frosted material blur fading in from transparent to opaque
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .white.opacity(0.25), location: 0.25),
                                .init(color: .white.opacity(0.85), location: 0.65),
                                .init(color: .white, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Dark gradient wash fading into pure black at the bottom to blend with tab bar
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.black.opacity(0.25), location: 0.25),
                        .init(color: Color.black.opacity(0.7), location: 0.65),
                        .init(color: Color.black.opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: 115)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .top)
        .task {
            await movieService.fetchMoviesFromBackend()
            startSmoothAutoScroll(total: movieService.publishedMovies.count)
        }
        .onChange(of: movies.count) { newCount in
            if selectedMovieIndex >= newCount {
                selectedMovieIndex = max(0, newCount - 1)
            }
            startSmoothAutoScroll(total: newCount)
        }
        .onDisappear {
            stopAutoScroll()
        }
    }

    private func startSmoothAutoScroll(total: Int) {
        stopAutoScroll()
        guard total > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { _ in
            Task { @MainActor in
                guard !isUserInteracting, total > 1 else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    selectedMovieIndex = (selectedMovieIndex + 1) % total
                }
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}

// Hero Slide matching the user's screenshot
public struct HomeHeroSlide: View {
    public let movie: Movie
    public let width: CGFloat
    public let height: CGFloat
    public let onBook: () -> Void
    public let onDetails: () -> Void

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Poster Artwork extending full height
            RobustAsyncImage(candidateURLs: [movie.resolvedPosterURL, movie.resolvedBackdropURL].compactMap { $0 }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                PosterFallback(movie: movie)
            }
            .frame(width: width, height: height)
            .clipped()

            // Smooth Multi-stop Dark Gradient Overlay for bottom text legibility
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.black.opacity(0.35), location: 0.54),
                    .init(color: Color.black.opacity(0.85), location: 0.78),
                    .init(color: Color.black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: height)

            // Content Overlay: Title, Metadata, Synopsis, and Buttons
            VStack(spacing: 8) {
                // Movie Title (non-rounded heavy system typography)
                Text(movie.title)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.8), radius: 8, y: 3)
                    .padding(.horizontal, 24)

                // Metadata Pill Row (e.g. 🛍️ Movie • Horror • [8.5])
                HStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 11))
                    Text("Movie")
                    Text("•")
                    Text(movie.genre)
                    Text("•")
                    Text("[\(movie.rating)]")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .padding(.horizontal, 12)
                .padding(.vertical, 3)

                // Synopsis (2 lines max, centered)
                Text(movie.description.isEmpty ? movie.tagline : movie.description)
                    .font(.system(size: 13, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .padding(.horizontal, 28)
                    .padding(.top, 2)

                // Action Buttons Row: [ (i) More Info ] and [ + ]
                HStack(spacing: 12) {
                    // "More Info" Pill Button (White capsule with black text)
                    Button(action: onDetails) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .bold))
                            Text("More Info")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 28)
                        .frame(height: 48)
                        .background(Color.white, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }

                    // "+" Button (Circular button to Book Tickets)
                    Button(action: onBook) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.22), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 6)
            }
            .padding(.bottom, 12)
        }
        .frame(width: width, height: height)
    }
}

// Compact Numbered Chart Card matching Apple TV reference
public struct TopChartMovieCard: View {
    public let rank: Int
    public let movie: Movie
    public let onTap: () -> Void
    public let onBook: () -> Void

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Poster Artwork (Compact width 98, height 145)
                RobustAsyncImage(candidateURLs: [movie.resolvedPosterURL, movie.resolvedBackdropURL].compactMap { $0 }) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(AppTheme.passBackground)
                }
                .frame(width: 98, height: 145)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))

                // Subtle gradient on top-left so rank number always pops
                LinearGradient(
                    colors: [Color.black.opacity(0.7), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Big Bold White Rank Number in Top Left (Non-rounded heavy font)
                Text("\(rank)")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.85), radius: 3, x: 1, y: 1)
                    .padding([.top, .leading], 7)
            }
            .frame(width: 98, height: 145)
        }
        .buttonStyle(.plain)
    }
}

public struct PosterFallback: View {
    public let movie: Movie

    public init(movie: Movie) {
        self.movie = movie
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: [movie.accent, .black], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 12) {
                Image(systemName: "film.fill").font(.system(size: 42, weight: .light))
                Text(movie.title.uppercased())
                    .font(.system(size: 24, weight: .heavy))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white.opacity(0.88))
            .padding(28)
        }
    }
}
