//
//  MovieDetailView.swift
//  MOVEI
//

import SwiftUI

public struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let movie: Movie
    public let onProceedToBooking: () -> Void

    public init(movie: Movie, onProceedToBooking: @escaping () -> Void) {
        self.movie = movie
        self.onProceedToBooking = onProceedToBooking
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Backdrop with navigation controls
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        RobustAsyncImage(candidateURLs: movie.allBackdropCandidateURLs) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(AppTheme.passBackground)
                        }
                        .frame(width: geo.size.width, height: 360)
                        .clipped()
                    }
                    .frame(height: 360)

                    LinearGradient(colors: [.black.opacity(0.35), .clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                        .allowsHitTesting(false)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .padding(18)
                }
                .frame(height: 360)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppTheme.ink)

                        Text(movie.tagline)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").foregroundStyle(.orange)
                                Text(movie.rating).font(.subheadline.bold())
                            }
                            Text("•").foregroundStyle(AppTheme.muted)
                            Text(movie.genre).font(.subheadline).foregroundStyle(AppTheme.muted)
                            Text("•").foregroundStyle(AppTheme.muted)
                            Text(movie.runtime).font(.subheadline).foregroundStyle(AppTheme.muted)
                        }
                        .padding(.top, 4)
                    }

                    // Synopsis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SYNOPSIS")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        Text(movie.description)
                            .font(.callout)
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.ink.opacity(0.85))
                    }

                    // Book CTA
                    Button {
                        dismiss()
                        onProceedToBooking()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "ticket.fill")
                            Text("Book Tickets")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.lime, in: Capsule())
                        .shadow(color: AppTheme.lime.opacity(0.35), radius: 10, y: 3)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.canvas.ignoresSafeArea())
    }
}
