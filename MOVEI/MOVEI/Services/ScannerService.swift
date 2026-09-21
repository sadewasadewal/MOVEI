//
//  ScannerService.swift
//  MOVEI
//

import SwiftUI
import Combine

public struct AdmissionResult {
    public let isValid: Bool
    public let statusType: StatusType
    public let title: String
    public let message: String
    public let ticketCode: String
    public let movieTitle: String?
    public let posterURL: String?
    public let customerName: String?
    public let cinemaName: String?
    public let screenName: String?
    public let seat: String?
    public let showtime: Date?
    public let scannedAt: Date?

    public enum StatusType {
        case valid
        case alreadyUsed
        case wrongCinema
        case cancelled
        case expired
        case invalid
    }

    public init(
        isValid: Bool,
        statusType: StatusType,
        title: String,
        message: String,
        ticketCode: String,
        movieTitle: String? = nil,
        posterURL: String? = nil,
        customerName: String? = nil,
        cinemaName: String? = nil,
        screenName: String? = nil,
        seat: String? = nil,
        showtime: Date? = nil,
        scannedAt: Date? = nil
    ) {
        self.isValid = isValid
        self.statusType = statusType
        self.title = title
        self.message = message
        self.ticketCode = ticketCode
        self.movieTitle = movieTitle
        self.posterURL = posterURL
        self.customerName = customerName
        self.cinemaName = cinemaName
        self.screenName = screenName
        self.seat = seat
        self.showtime = showtime
        self.scannedAt = scannedAt
    }
}

@MainActor
public final class ScannerService: ObservableObject {
    public static let shared = ScannerService()

    @Published public var assignedCinema: Cinema = Cinema(
        id: "cinemax-colombo",
        name: "Cinemax Colombo",
        address: "125 Galle Road, Colombo 03"
    )
    @Published public var recentScans: [TicketScan] = []
    @Published public var totalAdmissionsToday: Int = 0
    @Published public var isValidating: Bool = false

    private init() {
        self.recentScans = []
    }

    public func validateTicket(barcode: String, staffName: String = "Staff Scanner") async -> AdmissionResult {
        isValidating = true
        defer { isValidating = false }

        let cleanCode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        let ticketService = TicketService.shared

        // 1. Search local wallet first
        var targetTicket = ticketService.tickets.first(where: {
            $0.ticketCode.localizedCaseInsensitiveCompare(cleanCode) == .orderedSame ||
            $0.barcodeValue.localizedCaseInsensitiveCompare(cleanCode) == .orderedSame
        })

        // 2. If not found locally, query Web Admin API
        if targetTicket == nil {
            let baseURL = MovieService.shared.activeBaseURL
            if let encodedCode = cleanCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "\(baseURL)/api/tickets?code=\(encodedCode)") {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let item = json["ticket"] as? [String: Any] {
                        let code = item["ticket_code"] as? String ?? cleanCode
                        let t = Ticket(
                            id: item["id"] as? String ?? UUID().uuidString,
                            bookingID: item["booking_id"] as? String ?? "MOV-REMOTE",
                            showID: item["show_id"] as? String ?? "show-01",
                            userID: item["user_id"] as? String ?? "guest",
                            seatID: "seat-01",
                            seatLabel: item["seat_label"] as? String ?? "General",
                            ticketCode: code,
                            barcodeValue: item["barcode_value"] as? String ?? code,
                            status: item["status"] as? String ?? "confirmed",
                            scannedAt: nil,
                            scannedBy: nil,
                            movieTitle: item["movie_title"] as? String ?? "Cinema Pass",
                            posterURL: item["poster_url"] as? String ?? "",
                            backdropURL: item["backdrop_url"] as? String ?? "",
                            cinemaName: item["cinema_name"] as? String ?? assignedCinema.name,
                            screenName: item["screen_name"] as? String ?? "Screen 04",
                            showtime: Date().addingTimeInterval(3600)
                        )
                        ticketService.addTicket(t)
                        targetTicket = t
                    }
                } catch {
                    // Ignore network failure
                }
            }
        }

        // 3. Fallback check: If code is a demo test code, create on-the-fly ticket if missing
        if targetTicket == nil {
            if cleanCode == "MOV-75EB31-01" {
                let demo = Ticket(
                    bookingID: "MOV-75EB31",
                    showID: "show-wicked-01",
                    userID: "customer-01",
                    seatID: "s04-B4",
                    seatLabel: "B4 · B5",
                    ticketCode: "MOV-75EB31-01",
                    barcodeValue: "MOV-75EB31-01",
                    status: "confirmed",
                    movieTitle: "Wicked",
                    posterURL: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&h=900&q=80",
                    backdropURL: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=1920&h=1080&q=80",
                    cinemaName: "Cinemax Colombo",
                    screenName: "Screen 04",
                    showtime: Date().addingTimeInterval(3600 * 2)
                )
                ticketService.addTicket(demo)
                targetTicket = demo
            } else if cleanCode == "MOV-92FA44-01" {
                let demo = Ticket(
                    bookingID: "MOV-92FA44",
                    showID: "show-spiderman-01",
                    userID: "customer-02",
                    seatID: "s02-C2",
                    seatLabel: "C2 · C3",
                    ticketCode: "MOV-92FA44-01",
                    barcodeValue: "MOV-92FA44-01",
                    status: "confirmed",
                    movieTitle: "Spider-Man: Brand New Day",
                    posterURL: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=1200&q=90",
                    backdropURL: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=1800&q=90",
                    cinemaName: "Cinemax Colombo",
                    screenName: "Screen 02",
                    showtime: Date().addingTimeInterval(3600 * 4)
                )
                ticketService.addTicket(demo)
                targetTicket = demo
            }
        }

        guard let ticket = targetTicket else {
            let scan = TicketScan(ticketCode: cleanCode, scannerID: "scanner-04", cinemaID: assignedCinema.id, result: "invalid")
            recentScans.insert(scan, at: 0)
            return AdmissionResult(
                isValid: false,
                statusType: .invalid,
                title: "INVALID TICKET",
                message: "No ticket record found matching code: \(cleanCode)",
                ticketCode: cleanCode
            )
        }

        // 4. Duplicate entry check
        if ticket.status == "used" || ticket.status == "torn" {
            let scan = TicketScan(
                ticketID: ticket.id,
                ticketCode: cleanCode,
                scannerID: "scanner-04",
                cinemaID: assignedCinema.id,
                result: "already_used",
                movieTitle: ticket.movieTitle,
                customerName: "Customer",
                seat: ticket.seatLabel
            )
            recentScans.insert(scan, at: 0)
            return AdmissionResult(
                isValid: false,
                statusType: .alreadyUsed,
                title: "ALREADY TORN & USED",
                message: "This pass was already admitted at \(ticket.scannedAt?.formatted(date: .omitted, time: .shortened) ?? "earlier").",
                ticketCode: cleanCode,
                movieTitle: ticket.movieTitle,
                posterURL: ticket.posterURL,
                customerName: "Customer",
                cinemaName: ticket.cinemaName,
                screenName: ticket.screenName,
                seat: ticket.seatLabel,
                showtime: ticket.showtime,
                scannedAt: ticket.scannedAt
            )
        }

        // 5. Venue check
        if !ticket.cinemaName.localizedCaseInsensitiveContains(assignedCinema.name) &&
           !assignedCinema.name.localizedCaseInsensitiveContains(ticket.cinemaName) {
            let scan = TicketScan(
                ticketID: ticket.id,
                ticketCode: cleanCode,
                scannerID: "scanner-04",
                cinemaID: assignedCinema.id,
                result: "wrong_cinema",
                movieTitle: ticket.movieTitle,
                customerName: "Customer",
                seat: ticket.seatLabel
            )
            recentScans.insert(scan, at: 0)
            return AdmissionResult(
                isValid: false,
                statusType: .wrongCinema,
                title: "WRONG VENUE",
                message: "Ticket is valid only at: \(ticket.cinemaName)",
                ticketCode: cleanCode,
                movieTitle: ticket.movieTitle,
                posterURL: ticket.posterURL,
                cinemaName: ticket.cinemaName,
                screenName: ticket.screenName,
                seat: ticket.seatLabel,
                showtime: ticket.showtime
            )
        }

        // 6. Valid Admission: Mark used, auto-tear, and record in Web Admin!
        ticketService.markTicketUsed(ticketCode: cleanCode, scannerStaff: staffName)
        totalAdmissionsToday += 1

        let customerDisplayName = AuthService.shared.currentUser?.fullName ?? "Customer"
        let scan = TicketScan(
            ticketID: ticket.id,
            ticketCode: cleanCode,
            scannerID: "scanner-04",
            cinemaID: assignedCinema.id,
            result: "valid",
            movieTitle: ticket.movieTitle,
            customerName: customerDisplayName,
            seat: ticket.seatLabel
        )
        recentScans.insert(scan, at: 0)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        return AdmissionResult(
            isValid: true,
            statusType: .valid,
            title: "VALID TICKET",
            message: "Admission authorized. Ticket torn & recorded in Web Admin.",
            ticketCode: cleanCode,
            movieTitle: ticket.movieTitle,
            posterURL: ticket.posterURL,
            customerName: customerDisplayName,
            cinemaName: ticket.cinemaName,
            screenName: ticket.screenName,
            seat: ticket.seatLabel,
            showtime: ticket.showtime,
            scannedAt: Date()
        )
    }
}
