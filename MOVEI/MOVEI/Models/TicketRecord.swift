//
//  TicketRecord.swift
//  MOVEI
//

import Foundation
import SwiftData

@Model
public final class TicketRecord {
    public var id: String
    public var movieID: String
    public var movieTitle: String
    public var posterURL: String
    public var backdropURL: String
    public var accentHex: String
    public var cinema: String
    public var showtime: Date
    public var seats: String
    public var status: String

    public init(id: String, movieID: String, movieTitle: String, posterURL: String, backdropURL: String, accentHex: String, cinema: String, showtime: Date, seats: String, status: String = "upcoming") {
        self.id = id
        self.movieID = movieID
        self.movieTitle = movieTitle
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.accentHex = accentHex
        self.cinema = cinema
        self.showtime = showtime
        self.seats = seats
        self.status = status
    }

    public convenience init(from ticket: Ticket) {
        self.init(
            id: ticket.ticketCode,
            movieID: ticket.showID,
            movieTitle: ticket.movieTitle,
            posterURL: ticket.resolvedPosterURL?.absoluteString ?? ticket.posterURL,
            backdropURL: ticket.resolvedBackdropURL?.absoluteString ?? ticket.backdropURL,
            accentHex: "lime",
            cinema: ticket.cinemaName,
            showtime: ticket.showtime,
            seats: ticket.seatLabel,
            status: ticket.status
        )
    }
}
