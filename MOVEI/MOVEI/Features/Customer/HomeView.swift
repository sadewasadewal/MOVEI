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
                            // Full-bleed Native Paging Poster Carousel (120Hz smooth ProMotion scrolling)
                            GeometryReader { proxy in
                                let width = proxy.size.width
                                let height = proxy.size.height

                                TabView(selection: $selectedMovieIndex) {
                                    ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                                        HomeHeroSlide(
                                            movie: movie,
                                            width: width,
                                            height: height,
                                            isSelected: index == selectedMovieIndex,
                                            onBook: { onBook(movie) },
                                            onDetails: { onDetails(movie) }
                                        )
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
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

                    // 4:5 Size MOVEI Pass Subscription Section with LottieFiles Animation & 20% OFF
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Text("Exclusive Membership")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                        MoviePassSubscriptionCard()
                    }

                    // Minimal About Us Section
                    MinimalAboutUsSection()
                        .padding(.bottom, 130)
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
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                guard total > 1 else { return }
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

// Hero Slide with silky smooth title loading and ticket icon
public struct HomeHeroSlide: View {
    public let movie: Movie
    public let width: CGFloat
    public let height: CGFloat
    public let isSelected: Bool
    public let onBook: () -> Void
    public let onDetails: () -> Void

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Poster Artwork extending full height
            RobustAsyncImage(candidateURLs: movie.allPosterCandidateURLs) { image in
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

            // Content Overlay: Title, Metadata, Synopsis, and Buttons with Smooth Spring Transitions
            VStack(spacing: 6) {
                // Movie Title (elegant bold system typography, animated smoothly into place)
                Text(movie.title)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.85), radius: 8, y: 3)
                    .padding(.horizontal, 24)
                    .opacity(isSelected ? 1.0 : 0.3)
                    .offset(y: isSelected ? 0 : 8)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isSelected)

                // Metadata Pill Row (Changed bag.fill store icon to cinema ticket.fill)
                HStack(spacing: 6) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text("Movie")
                    Text("•")
                    Text(movie.genre)
                    Text("•")
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.yellow)
                        Text(movie.rating)
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .opacity(isSelected ? 1.0 : 0.2)
                .offset(y: isSelected ? 0 : 6)
                .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.03), value: isSelected)

                // Synopsis (2 lines max, centered, compact, smoothly faded)
                Text(movie.description.isEmpty ? movie.tagline : movie.description)
                    .font(.system(size: 12, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .padding(.horizontal, 28)
                    .padding(.top, 1)
                    .opacity(isSelected ? 0.88 : 0.0)
                    .offset(y: isSelected ? 0 : 5)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: isSelected)

                // Action Buttons Row: [ (i) More Info ] and [ + ]
                HStack(spacing: 12) {
                    // "More Info" Pill Button (White capsule with black text)
                    Button(action: onDetails) {
                        HStack(spacing: 7) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 15, weight: .bold))
                            Text("More Info")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(Color.white, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }

                    // "+" Button (Circular button to Book Tickets)
                    Button(action: onBook) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.22), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 2)
                .opacity(isSelected ? 1.0 : 0.3)
                .offset(y: isSelected ? 0 : 4)
                .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.09), value: isSelected)
            }
            .padding(.bottom, 4)
        }
        .frame(width: width, height: height)
    }
}

// 4:5 Size MOVEI Pass Subscription Card with LottieFiles Animation & 20% OFF
public struct MoviePassSubscriptionCard: View {
    @State private var isSubscribed = false
    @State private var showAlert = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Inner Content
            VStack(alignment: .leading, spacing: 14) {
                // Header: Badge + 20% OFF Discount Pill
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.35))
                        Text("MOVEI PASS")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(1.4)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))

                    Spacer()

                    // Vibrant 20% OFF Discount Badge
                    HStack(spacing: 5) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10, weight: .heavy))
                        Text("20% OFF")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.4), radius: 6, y: 2)
                }

                // Title & Subheading
                VStack(alignment: .leading, spacing: 3) {
                    Text("All-Access Cinema Pass")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Watch unlimited premieres with 20% off all tickets & snacks")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.68))
                }

                Spacer(minLength: 4)

                // Lottie Animation Container (Monochrome animated ticket pass with glowing scanline & holographic sheen)
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    LottieAnimationView()
                        .scaleEffect(0.95)
                        .padding(.vertical, 4)
                }
                .frame(maxHeight: 140)

                Spacer(minLength: 4)

                // Perks List
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                        Text("20% off every ticket, popcorn & concession")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                        Text("Zero online booking fees & free instant cancellation")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                        Text("Priority VIP line entry & advance premiere seats")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                }

                // Price and CTA Button
                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Rs. 1,499")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("/ month")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))

                        Text("Rs. 1,899")
                            .font(.system(size: 13, weight: .medium))
                            .strikethrough(true, color: Color.white.opacity(0.45))
                            .foregroundStyle(Color.white.opacity(0.45))

                        Spacer()

                        Text("SAVE 20%")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.15), in: Capsule())
                    }

                    Button {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        isSubscribed = true
                        showAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(isSubscribed ? "MOVEI Pass Active" : "Get MOVEI Pass — 20% Off")
                                .font(.system(size: 14.5, weight: .bold))

                            Image(systemName: isSubscribed ? "checkmark" : "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.white.opacity(0.2), radius: 8, y: 3)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4.0 / 5.0, contentMode: .fit) // Exact 4:5 aspect ratio
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.10, blue: 0.16),
                            Color(red: 0.08, green: 0.08, blue: 0.12),
                            Color(red: 0.04, green: 0.04, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.65), radius: 18, y: 8)
        )
        .padding(.horizontal, 20)
        .alert("MOVEI Pass Activated", isPresented: $showAlert) {
            Button("Awesome", role: .cancel) { }
        } message: {
            Text("Your 20% discount is now active! All movie tickets and snacks will automatically reflect your member pricing at checkout.")
        }
    }
}

// Minimalist About Us Section
public struct MinimalAboutUsSection: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Clean subtle divider line
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            // Header & Story
            VStack(alignment: .leading, spacing: 10) {
                Text("ABOUT MOVEI")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(Color.white.opacity(0.45))

                Text("Cinema Reimagined.")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text("MOVEI crafts a refined moviegoing sanctuary combining next-gen 4K RGB laser projection, acoustic calibration by Dolby Atmos, and effortless paperless entry directly from your iPhone.")
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(Color.white.opacity(0.68))
            }
            .padding(.horizontal, 20)

            // Minimalist 3-Pillar Spec Cards
            HStack(spacing: 10) {
                MinimalFeaturePill(
                    icon: "sparkles.tv.fill",
                    title: "4K Laser",
                    caption: "HDR RGB Clarity"
                )

                MinimalFeaturePill(
                    icon: "waveform.path",
                    title: "Dolby Atmos",
                    caption: "360° Spatial Sound"
                )

                MinimalFeaturePill(
                    icon: "qrcode",
                    title: "Paperless",
                    caption: "Instant Turnstile"
                )
            }
            .padding(.horizontal, 20)

            // Location & Hours Note
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Text("Flagship: One Galle Face Mall, Level 5, Colombo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Text("Showtimes Daily: 10:00 AM – 11:30 PM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // Micro brand footer
            Text("MOVEI CINEMAS • DESIGNED FOR FILM LOVERS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.25))
                .padding(.horizontal, 20)
                .padding(.top, 4)
        }
    }
}

// Minimal Feature Spec Pill
public struct MinimalFeaturePill: View {
    public let icon: String
    public let title: String
    public let caption: String

    public init(icon: String, title: String, caption: String) {
        self.icon = icon
        self.title = title
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(.white)
                Text(caption)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.52))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
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
                RobustAsyncImage(candidateURLs: movie.allPosterCandidateURLs) { img in
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
