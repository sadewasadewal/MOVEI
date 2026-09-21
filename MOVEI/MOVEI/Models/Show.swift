//
//  Show.swift
//  MOVEI
//

import Foundation

public struct Show: Identifiable, Codable, Hashable {
    public let id: String
    public var movieID: String
    public var cinemaID: String
    public var screenID: String
    public var startTime: Date
    public var endTime: Date
    public var priceStandard: Double
    public var pricePremium: Double
    public var priceVIP: Double
    public var status: String

    public init(
        id: String = UUID().uuidString,
        movieID: String,
        cinemaID: String,
        screenID: String,
        startTime: Date,
        endTime: Date,
        priceStandard: Double = 1000.0,
        pricePremium: Double = 1500.0,
        priceVIP: Double = 2000.0,
        status: String = "scheduled"
    ) {
        self.id = id
        self.movieID = movieID
        self.cinemaID = cinemaID
        self.screenID = screenID
        self.startTime = startTime
        self.endTime = endTime
        self.priceStandard = priceStandard
        self.pricePremium = pricePremium
        self.priceVIP = priceVIP
        self.status = status
    }
}

public struct Booking: Identifiable, Codable, Hashable {
    public let id: String
    public var userID: String
    public var showID: String
    public var bookingReference: String
    public var totalAmount: Double
    public var currency: String
    public var status: String
    public var createdAt: Date

    public init(id: String = UUID().uuidString, userID: String, showID: String, bookingReference: String, totalAmount: Double, currency: String = "LKR", status: String = "confirmed", createdAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.showID = showID
        self.bookingReference = bookingReference
        self.totalAmount = totalAmount
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
    }
}

public struct Ticket: Identifiable, Codable, Hashable {
    public let id: String
    public var bookingID: String
    public var showID: String
    public var userID: String
    public var seatID: String
    public var seatLabel: String
    public var ticketCode: String
    public var barcodeValue: String
    public var price: Double
    public var status: String // reserved, confirmed, used, cancelled, expired
    public var scannedAt: Date?
    public var scannedBy: String?
    public var movieTitle: String
    public var posterURL: String
    public var backdropURL: String
    public var cinemaName: String
    public var screenName: String
    public var showtime: Date

    public var resolvedPosterURL: URL? {
        ImageURLResolver.resolve(posterURL, fallback: backdropURL, baseURL: MovieService.shared.activeBaseURL)
    }

    public var resolvedBackdropURL: URL? {
        ImageURLResolver.resolve(backdropURL, fallback: posterURL, baseURL: MovieService.shared.activeBaseURL)
    }

    enum CodingKeys: String, CodingKey {
        case id, bookingID, showID, userID, seatID, seatLabel, ticketCode, barcodeValue, price, status, scannedAt, scannedBy, movieTitle, posterURL, backdropURL, cinemaName, screenName, showtime
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.bookingID = try container.decode(String.self, forKey: .bookingID)
        self.showID = try container.decode(String.self, forKey: .showID)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.seatID = try container.decode(String.self, forKey: .seatID)
        self.seatLabel = try container.decode(String.self, forKey: .seatLabel)
        self.ticketCode = try container.decode(String.self, forKey: .ticketCode)
        self.barcodeValue = try container.decode(String.self, forKey: .barcodeValue)
        self.price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        self.status = try container.decode(String.self, forKey: .status)
        self.scannedAt = try container.decodeIfPresent(Date.self, forKey: .scannedAt)
        self.scannedBy = try container.decodeIfPresent(String.self, forKey: .scannedBy)
        self.movieTitle = try container.decode(String.self, forKey: .movieTitle)
        self.posterURL = try container.decode(String.self, forKey: .posterURL)
        self.backdropURL = try container.decode(String.self, forKey: .backdropURL)
        self.cinemaName = try container.decode(String.self, forKey: .cinemaName)
        self.screenName = try container.decode(String.self, forKey: .screenName)
        self.showtime = try container.decode(Date.self, forKey: .showtime)
    }

    public init(
        id: String = UUID().uuidString,
        bookingID: String,
        showID: String,
        userID: String,
        seatID: String,
        seatLabel: String,
        ticketCode: String,
        barcodeValue: String,
        price: Double = 0,
        status: String = "confirmed",
        scannedAt: Date? = nil,
        scannedBy: String? = nil,
        movieTitle: String,
        posterURL: String,
        backdropURL: String,
        cinemaName: String,
        screenName: String,
        showtime: Date
    ) {
        self.id = id
        self.bookingID = bookingID
        self.showID = showID
        self.userID = userID
        self.seatID = seatID
        self.seatLabel = seatLabel
        self.ticketCode = ticketCode
        self.barcodeValue = barcodeValue
        self.price = price
        self.status = status
        self.scannedAt = scannedAt
        self.scannedBy = scannedBy
        self.movieTitle = movieTitle
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.cinemaName = cinemaName
        self.screenName = screenName
        self.showtime = showtime
    }
}

public struct TicketScan: Identifiable, Codable, Hashable {
    public let id: String
    public var ticketID: String?
    public var ticketCode: String
    public var scannerID: String
    public var cinemaID: String
    public var scannedAt: Date
    public var result: String // valid, already_used, invalid, wrong_cinema, cancelled, expired
    public var movieTitle: String?
    public var customerName: String?
    public var seat: String?

    public init(id: String = UUID().uuidString, ticketID: String? = nil, ticketCode: String, scannerID: String, cinemaID: String, scannedAt: Date = Date(), result: String, movieTitle: String? = nil, customerName: String? = nil, seat: String? = nil) {
        self.id = id
        self.ticketID = ticketID
        self.ticketCode = ticketCode
        self.scannerID = scannerID
        self.cinemaID = cinemaID
        self.scannedAt = scannedAt
        self.result = result
        self.movieTitle = movieTitle
        self.customerName = customerName
        self.seat = seat
    }
}

public struct Review: Identifiable, Codable, Hashable {
    public let id: String
    public var userID: String
    public var movieID: String
    public var rating: Double
    public var reviewText: String
    public var createdAt: Date

    public init(id: String = UUID().uuidString, userID: String, movieID: String, rating: Double, reviewText: String, createdAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.movieID = movieID
        self.rating = rating
        self.reviewText = reviewText
        self.createdAt = createdAt
    }
}
