//
//  WatchedView.swift
//  MOVEI
//

import SwiftUI

public struct WatchedView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var ticketService = TicketService.shared
    @State private var ratingMovieTitle: String?
    @State private var selectedRating: Double = 5.0
    @State private var reviewText: String = ""

    public init() {}

    private var watchedTickets: [Ticket] {
        ticketService.watchedTickets
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Watch History")
                            .font(.system(size: 34, weight: .bold))
                        Text("Your cinema memories and collectibles")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    if watchedTickets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.muted)
                            Text("No Watched Movies Yet")
                                .font(.headline)
                            Text("When a show finishes or your ticket is admitted, it will appear here.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.muted)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 44)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 20)
                    } else {
                        ForEach(watchedTickets) { ticket in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 14) {
                                    RobustAsyncImage(candidateURLs: [ticket.resolvedPosterURL, ticket.resolvedBackdropURL].compactMap { $0 }) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(AppTheme.passBackground)
                                    }
                                    .frame(width: 60, height: 86)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("COLLECTIBLE PASS")
                                                .font(.system(size: 9, weight: .black))
                                                .tracking(1.4)
                                                .foregroundStyle(AppTheme.lime)
                                            Spacer()
                                            Text(ticket.showtime, format: .dateTime.month(.abbreviated).day())
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(AppTheme.muted)
                                        }

                                        Text(ticket.movieTitle)
                                            .font(.headline.weight(.bold))
                                            .lineLimit(1)

                                        Text("\(ticket.cinemaName) · \(ticket.seatLabel)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.muted)

                                        Button {
                                            ratingMovieTitle = ticket.movieTitle
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .font(.caption2)
                                                Text("Rate & Review")
                                                    .font(.caption.weight(.bold))
                                            }
                                            .foregroundStyle(AppTheme.ink)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(AppTheme.lime.opacity(0.35))
                                            .clipShape(Capsule())
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .padding(16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.surface, in: Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 1)
                    }
                }
            }
            .sheet(item: $ratingMovieTitle) { title in
                ReviewModalView(movieTitle: title)
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

public struct ReviewModalView: View {
    @Environment(\.dismiss) private var dismiss
    public let movieTitle: String
    @State private var stars: Int = 5
    @State private var review: String = ""

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Rate & Review")
                        .font(.title2.bold())
                    Text(movieTitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 24)

                // Star Picker
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            stars = i
                        } label: {
                            Image(systemName: i <= stars ? "star.fill" : "star")
                                .font(.title)
                                .foregroundStyle(Color.orange)
                        }
                    }
                }

                TextField("Write your thoughts on the movie...", text: $review, axis: .vertical)
                    .lineLimit(4...6)
                    .padding(16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                Button {
                    dismiss()
                } label: {
                    Text("Submit Review")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.lime, in: Capsule())
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
