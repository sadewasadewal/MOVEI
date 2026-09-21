//
//  TicketService.swift
//  MOVEI
//

import SwiftUI
import Combine
import SwiftData

@MainActor
public final class TicketService: ObservableObject {
    public static let shared = TicketService()

    @Published public var tickets: [Ticket] = []

    private init() {
        loadDefaultTickets()
    }

    private func loadDefaultTickets() {
        // Brand new system starts with empty tickets wallet
        self.tickets = []
    }

    public func addTicket(_ ticket: Ticket) {
        tickets.insert(ticket, at: 0)
        Task {
            await syncNewTicketToBackend(ticket)
        }
    }

    public func deleteTicket(_ ticket: Ticket) {
        tickets.removeAll { $0.id == ticket.id }
    }

    public func clearAllTickets() {
        tickets.removeAll()
    }

    public func markTicketUsed(ticketCode: String, scannerStaff: String = "Staff Scanner") {
        let cleanCode = ticketCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if let idx = tickets.firstIndex(where: {
            $0.ticketCode.localizedCaseInsensitiveCompare(cleanCode) == .orderedSame ||
            $0.barcodeValue.localizedCaseInsensitiveCompare(cleanCode) == .orderedSame
        }) {
            tickets[idx].status = "used"
            tickets[idx].scannedAt = Date()
            tickets[idx].scannedBy = scannerStaff
        }
        Task {
            await syncTicketScanToBackend(ticketCode: cleanCode, scannerStaff: scannerStaff)
        }
    }

    public func syncTicketScanToBackend(ticketCode: String, scannerStaff: String) async {
        let baseURL = MovieService.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/api/tickets") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 4.0

        let payload: [String: Any] = [
            "action": "scan_and_tear",
            "ticketCode": ticketCode,
            "scannerStaff": scannerStaff
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("[TicketService] Successfully marked ticket \(ticketCode) as torn in Web Admin")
            }
        } catch {
            print("[TicketService] Web Admin sync notice: \(error.localizedDescription)")
        }
    }

    private func syncNewTicketToBackend(_ ticket: Ticket) async {
        let baseURL = MovieService.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/api/tickets") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 4.0

        let userName = AuthService.shared.currentUser?.fullName ?? "Customer"
        let rawEmail = AuthService.shared.currentUserEmail
        let userEmail = rawEmail.isEmpty ? "\(userName.lowercased().filter { $0.isLetter })@movei.io" : rawEmail
        let payload: [String: Any] = [
            "id": ticket.id,
            "booking_id": ticket.bookingID,
            "show_id": ticket.showID,
            "user_id": ticket.userID,
            "customer_name": userName,
            "customer_email": userEmail,
            "movie_title": ticket.movieTitle,
            "cinema_name": ticket.cinemaName,
            "screen_name": ticket.screenName,
            "seat_label": ticket.seatLabel,
            "ticket_code": ticket.ticketCode,
            "barcode_value": ticket.barcodeValue,
            "price": ticket.price > 0 ? ticket.price : 2400.0,
            "status": ticket.status,
            "showtime": ticket.showtime.formatted(date: .abbreviated, time: .shortened),
            "poster_url": ticket.posterURL,
            "backdrop_url": ticket.backdropURL
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Silently ignore if offline
        }
    }

    public func fetchTicketsFromBackend() async {
        let baseURL = MovieService.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/api/tickets") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for item in jsonArray {
                    guard let code = item["ticket_code"] as? String ?? item["barcode_value"] as? String,
                          let status = item["status"] as? String else { continue }
                    if let idx = self.tickets.firstIndex(where: {
                        $0.ticketCode.localizedCaseInsensitiveCompare(code) == .orderedSame ||
                        $0.barcodeValue.localizedCaseInsensitiveCompare(code) == .orderedSame
                    }) {
                        self.tickets[idx].status = status
                    }
                }
            }
        } catch {
            // Offline fallback
        }
    }

    public var upcomingTickets: [Ticket] {
        tickets.filter { $0.status == "confirmed" || $0.status == "reserved" }
    }

    public var watchedTickets: [Ticket] {
        tickets.filter { $0.status == "used" || $0.showtime < Date() }
    }
}
