//
//  WalletTicketCard.swift
//  MOVEI
//

import SwiftUI

public func ticketArtworkCandidates(_ ticket: Ticket) -> [URL] {
    var list: [URL] = []
    for u in ticket.allBackdropCandidateURLs where !list.contains(u) { list.append(u) }
    for u in ticket.allPosterCandidateURLs where !list.contains(u) { list.append(u) }
    let cleanTicket = ticket.movieTitle.filter { $0.isLetter || $0.isNumber }.lowercased()
    if let movie = MovieService.shared.movies.first(where: {
        let cleanMovie = $0.title.filter { $0.isLetter || $0.isNumber }.lowercased()
        return cleanMovie == cleanTicket || cleanMovie.contains(cleanTicket) || cleanTicket.contains(cleanMovie) || $0.id == ticket.showID
    }) {
        for u in movie.allBackdropCandidateURLs where !list.contains(u) { list.append(u) }
        for u in movie.allPosterCandidateURLs where !list.contains(u) { list.append(u) }
    }
    return list
}

public struct WalletTicketCard: View {
    public let ticket: Ticket

    public init(ticket: Ticket) {
        self.ticket = ticket
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RobustAsyncImage(candidateURLs: ticketArtworkCandidates(ticket)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(AppTheme.passBackground)
                }
                .frame(height: 250)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.7), .clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("MOVEI CINEMA")
                            .font(.caption.weight(.black))
                            .tracking(2)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(ticket.showtime, format: .dateTime.day().month(.abbreviated))
                                .font(.subheadline.weight(.black))
                            Text(ticket.showtime, format: .dateTime.hour().minute())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    Text("MOVIE PASS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.lime)

                    Text(ticket.movieTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(20)
            }
            .frame(height: 250)

            VStack(spacing: 16) {
                HStack {
                    PassDetail(label: "VENUE", value: ticket.cinemaName)
                    Spacer()
                    PassDetail(label: "SCREEN", value: ticket.screenName)
                    PassDetail(label: "SEATS", value: ticket.seatLabel)
                }

                // Dotted perforation divider
                DashedLine()
                    .stroke(AppTheme.muted.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .frame(height: 1.5)
                    .padding(.vertical, 4)

                // Barcode representation
                VStack(spacing: 8) {
                    ZStack {
                        BarcodeView(value: ticket.barcodeValue)
                            .frame(height: 52)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .opacity((ticket.status == "used" || ticket.status == "torn") ? 0.35 : 1.0)

                        if ticket.status == "used" || ticket.status == "torn" {
                            HStack(spacing: 5) {
                                Image(systemName: "scissors")
                                Text("TORN & ADMITTED")
                            }
                            .font(.system(size: 13, weight: .black))
                            .tracking(1.4)
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                            )
                            .rotationEffect(.degrees(-5))
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        }
                    }

                    HStack {
                        Text(ticket.ticketCode)
                            .font(.caption2.monospaced())
                            .foregroundStyle(AppTheme.muted)

                        if let scanned = ticket.scannedAt {
                            Spacer()
                            Text("Admitted \(scanned.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
            .padding(20)
            .background(AppTheme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
    }
}

public struct WalletPeekCard: View {
    public let ticket: Ticket

    public init(ticket: Ticket) {
        self.ticket = ticket
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MOVEI PASS")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.lime)

                    Text(ticket.movieTitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Text(ticket.showtime, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RobustAsyncImage(candidateURLs: ticketArtworkCandidates(ticket)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    AppTheme.passBackground
                }
                LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: -4)
    }
}

public struct WalletMiniCard: View {
    public let ticket: Ticket

    public init(ticket: Ticket) {
        self.ticket = ticket
    }

    public var body: some View {
        HStack(spacing: 14) {
            RobustAsyncImage(candidateURLs: ticketArtworkCandidates(ticket)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(AppTheme.passBackground)
            }
            .frame(width: 50, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.status == "used" ? "WATCHED" : "UPCOMING SHOW")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(ticket.status == "used" ? AppTheme.muted : AppTheme.lime)

                Text(ticket.movieTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text("\(ticket.cinemaName) · \(ticket.showtime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

public struct PassDetail: View {
    public let label: String
    public let value: String
    public var lightText = false

    public init(label: String, value: String, lightText: Bool = false) {
        self.label = label
        self.value = value
        self.lightText = lightText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(lightText ? .white.opacity(0.65) : AppTheme.muted)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(lightText ? .white : AppTheme.ink)
                .lineLimit(1)
        }
    }
}

public struct PassActionRow: View {
    public let title: String
    public let subtitle: String
    public let icon: String

    public init(title: String, subtitle: String, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Image(systemName: icon).foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

public struct PassActionTile: View {
    public let title: String
    public let subtitle: String
    public let icon: String

    public init(title: String, subtitle: String, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(AppTheme.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.bold))
                Text(subtitle).font(.caption).foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

public struct DashedLine: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
