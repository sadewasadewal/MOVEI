//
//  BookingView.swift
//  MOVEI
//

import SwiftUI
import SwiftData

public struct BookingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var cinemaService = CinemaService.shared
    @ObservedObject private var showService = ShowService.shared
    @ObservedObject private var bookingService = BookingService.shared
    @ObservedObject private var ticketService = TicketService.shared

    public let movie: Movie
    public let onCompleted: (Ticket) -> Void

    @State private var selectedCinemaIndex = 0
    @State private var selectedShowIndex = 0
    @State private var selectedSeats: Set<Seat> = []
    @State private var isCheckingOut = false
    @State private var errorMessage: String?
    @State private var isSeatViewerExpanded = false

    public init(movie: Movie, onCompleted: @escaping (Ticket) -> Void) {
        self.movie = movie
        self.onCompleted = onCompleted
    }

    private var currentCinema: Cinema? {
        guard !cinemaService.cinemas.isEmpty else { return nil }
        return cinemaService.cinemas[selectedCinemaIndex % cinemaService.cinemas.count]
    }

    private var availableShows: [Show] {
        showService.shows(for: movie.id)
    }

    private var currentShow: Show? {
        let shows = availableShows
        guard !shows.isEmpty else { return nil }
        return shows[selectedShowIndex % shows.count]
    }

    private var currentSeats: [Seat] {
        guard let cinema = currentCinema,
              let screen = cinemaService.screens(for: cinema.id).first else { return [] }
        return cinemaService.seats(for: screen.id)
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                scrollContent
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Book Tickets")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        bookingService.releaseHolds(seats: Array(selectedSeats))
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            holdTimerSection

            cinemaPickerSection

            showtimePickerSection

            seatCategoriesSection

            chooseSeatsSection

            if let show = currentShow {
                reservationSection(show: show)
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 16) {
            AsyncImage(url: movie.resolvedPosterURL ?? movie.resolvedBackdropURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.white.opacity(0.1))
            }
            .frame(width: 72, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text("BOOKING TICKETS")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.5))

                Text(movie.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(movie.genre)  •  \(movie.runtime)")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))

                if currentShow != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "ticket.fill")
                            .font(.caption2)
                        Text("Free Ticket Reservation")
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var holdTimerSection: some View {
        if bookingService.activeHoldTimerSeconds > 0 {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundStyle(.white)
                Text("Seats reserved for:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                let mins = bookingService.activeHoldTimerSeconds / 60
                let secs = bookingService.activeHoldTimerSeconds % 60
                Text(String(format: "%02d:%02d", mins, secs))
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var seatCategoriesSection: some View {
        if currentShow != nil {
            HStack(spacing: 12) {
                SeatTierPill(name: "Standard", subtitle: "Balcony", fillOpacity: 0.16)
                SeatTierPill(name: "Premium", subtitle: "Prime", fillOpacity: 0.26)
                SeatTierPill(name: "VIP", subtitle: "Recliner", fillOpacity: 0.40)
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var chooseSeatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CHOOSE SEATS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                // Expand / Unexpand Seat Viewer Button
                Button {
                    withAnimation {
                        isSeatViewerExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isSeatViewerExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(isSeatViewerExpanded ? "Compact View" : "Expand Hall View")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12), in: Capsule())
                }
            }

            // Selected Seats interactive chips with one-tap removal
            if !selectedSeats.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedSeats).sorted(by: { $0.label < $1.label })) { seat in
                            Button {
                                withAnimation {
                                    _ = selectedSeats.remove(seat)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(seat.label)
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .opacity(0.7)
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white, in: Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            // Monochrome Seat Map Card
            VStack(spacing: 16) {
                // Cinema Screen curve banner in stark monochrome
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color.white.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                        .shadow(color: Color.white.opacity(0.4), radius: 6, y: 1)

                    Text("CINEMA SCREEN")
                        .font(.system(size: 9, weight: .black))
                        .tracking(4)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 4)

                // Seat grid in Monochrome with Expand/Collapse support
                SeatMapViewMonochrome(
                    seats: currentSeats,
                    selectedSeats: $selectedSeats,
                    isExpanded: isSeatViewerExpanded,
                    bookedSeatIDs: bookingService.bookedSeatIDs,
                    heldSeatIDs: Set(bookingService.heldSeats.keys)
                ) { seat in
                    if let show = currentShow {
                        _ = bookingService.holdSeats(seats: Array(selectedSeats), for: show)
                    }
                }

                // Legend in Clean Monochrome
                HStack(spacing: 16) {
                    MonochromeLegend(fill: Color.white.opacity(0.18), stroke: Color.white.opacity(0.3), label: "Available")
                    MonochromeLegend(fill: Color.white, stroke: Color.white, label: "Selected")
                    MonochromeLegend(fill: Color.white.opacity(0.04), stroke: Color.white.opacity(0.08), label: "Reserved")
                }
                .padding(.top, 4)
            }
            .padding(18)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var cinemaPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT CINEMA")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.white.opacity(0.5))

            ForEach(Array(cinemaService.cinemas.enumerated()), id: \.element.id) { index, cinema in
                CinemaRowButton(
                    cinema: cinema,
                    isSelected: selectedCinemaIndex == index
                ) {
                    selectedCinemaIndex = index
                    selectedSeats.removeAll()
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var showtimePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT SHOWTIME")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.white.opacity(0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(availableShows.enumerated()), id: \.element.id) { index, show in
                        ShowtimeButton(
                            show: show,
                            isSelected: selectedShowIndex == index
                        ) {
                            selectedShowIndex = index
                            selectedSeats.removeAll()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func reservationSection(show: Show) -> some View {
        VStack(spacing: 14) {
            if !selectedSeats.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(selectedSeats.count) \(selectedSeats.count == 1 ? "Ticket" : "Tickets") Selected")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                        let seatList = selectedSeats.map { $0.label }.sorted().joined(separator: ", ")
                        Text("Seats: \(seatList)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Reservation Mode")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("Direct Pass")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // Pure Monochrome Booking Button - Book Tickets Only (No Payment)
            Button {
                performBooking(for: show)
            } label: {
                if isCheckingOut {
                    HStack(spacing: 8) {
                        ProgressView().tint(Color.black)
                        Text("Reserving Tickets...")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white, in: Capsule())
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "ticket.fill")
                            .font(.subheadline.weight(.bold))
                        Text(selectedSeats.isEmpty ? "Select Seats to Book" : "Book \(selectedSeats.count) Ticket\(selectedSeats.count == 1 ? "" : "s")")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(selectedSeats.isEmpty ? Color.white.opacity(0.4) : Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedSeats.isEmpty ? Color.white.opacity(0.1) : Color.white, in: Capsule())
                }
            }
            .disabled(selectedSeats.isEmpty || isCheckingOut)

            Text("Instant ticket reservation. Tickets are added directly to your wallet.")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private func performBooking(for show: Show) {
        Task {
            guard let cinema = currentCinema,
                  let screen = cinemaService.screens(for: cinema.id).first else { return }
            isCheckingOut = true
            let result = await bookingService.checkoutAndIssueTickets(
                seats: Array(selectedSeats),
                for: show,
                movie: movie,
                cinema: cinema,
                screen: screen,
                userID: AuthService.shared.currentUser?.id.uuidString ?? "guest"
            )
            isCheckingOut = false
            if result.success, let first = result.tickets.first {
                for t in result.tickets {
                    ticketService.addTicket(t)
                    let rec = TicketRecord(from: t)
                    modelContext.insert(rec)
                }
                try? modelContext.save()
                dismiss()
                onCompleted(first)
            } else {
                errorMessage = result.message
            }
        }
    }
}

private struct CinemaRowButton: View {
    let cinema: Cinema
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.4))
                Text(cinema.name)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(cinema.city)
                    .font(.caption.weight(.medium))
                    .opacity(0.7)
            }
            .padding(14)
            .background(isSelected ? Color.white : Color.white.opacity(0.06))
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

private struct ShowtimeButton: View {
    let show: Show
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(show.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.weight(.bold))
                Text("Standard Hall")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.8)
            }
            .frame(minWidth: 84)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.white.opacity(0.06))
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

private struct SeatTierPill: View {
    let name: String
    let subtitle: String
    let fillOpacity: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(name.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.6))
            Text(subtitle)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(fillOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct MonochromeLegend: View {
    let fill: Color
    let stroke: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(fill)
                .frame(width: 12, height: 12)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(stroke, lineWidth: 0.8))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
}

private struct CinemaSeatButton: View {
    let seat: Seat
    let isSelected: Bool
    let isBooked: Bool
    let isHeld: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isExpanded ? 3 : 2) {
                // Cinema Chair Headrest
                RoundedRectangle(cornerRadius: 2)
                    .fill(headrestColor)
                    .frame(height: isExpanded ? 5 : 3)
                    .padding(.horizontal, isExpanded ? 4 : 2)

                // Seat Cushion Body
                Text("\(seat.seatNumber)")
                    .font(.system(size: isExpanded ? 11 : 10, weight: .bold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, isExpanded ? 4 : 2)
            .padding(.bottom, isExpanded ? 2 : 1)
            .frame(width: isExpanded ? 42 : nil, height: isExpanded ? 46 : 34)
            .frame(maxWidth: isExpanded ? nil : .infinity)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 8 : 6))
            .overlay(
                RoundedRectangle(cornerRadius: isExpanded ? 8 : 6)
                    .stroke(borderColor, lineWidth: isSelected ? 1.2 : 0.8)
            )
        }
        .disabled(isBooked || isHeld)
    }

    private var headrestColor: Color {
        if isSelected { return Color.black.opacity(0.3) }
        if isBooked { return Color.white.opacity(0.06) }
        return Color.white.opacity(0.3)
    }

    private var backgroundColor: Color {
        if isSelected { return Color.white }
        if isBooked { return Color.white.opacity(0.04) }
        if isHeld { return Color.white.opacity(0.08) }
        switch seat.seatType {
        case .standard, .disabled: return Color.white.opacity(0.16)
        case .premium: return Color.white.opacity(0.26)
        case .vip: return Color.white.opacity(0.38)
        }
    }

    private var foregroundColor: Color {
        if isSelected { return Color.black }
        if isBooked { return Color.white.opacity(0.15) }
        return Color.white
    }

    private var borderColor: Color {
        if isSelected { return Color.white }
        if isBooked { return Color.white.opacity(0.05) }
        return Color.white.opacity(0.18)
    }
}

private struct SeatMapViewMonochrome: View {
    let seats: [Seat]
    @Binding var selectedSeats: Set<Seat>
    let isExpanded: Bool
    let bookedSeatIDs: Set<String>
    let heldSeatIDs: Set<String>
    var onSelect: ((Seat) -> Void)?

    private var groupedRows: [String: [Seat]] {
        Dictionary(grouping: seats, by: { $0.rowLabel })
    }

    private var sortedRowLabels: [String] {
        groupedRows.keys.sorted()
    }

    var body: some View {
        if isExpanded {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 10, weight: .bold))
                    Text("Pinch or scroll to explore theater hall")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.5))

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(sortedRowLabels, id: \.self) { row in
                            let rowSeats = (groupedRows[row] ?? []).sorted(by: { $0.seatNumber < $1.seatNumber })
                            let half = max(1, rowSeats.count / 2)
                            let leftWing = Array(rowSeats.prefix(half))
                            let rightWing = Array(rowSeats.dropFirst(half))

                            HStack(spacing: 8) {
                                Text(row)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .frame(width: 20)

                                HStack(spacing: 6) {
                                    ForEach(leftWing) { seat in
                                        seatButton(seat: seat, isExpanded: true)
                                    }
                                }

                                // Center Aisle Walkway
                                VStack(spacing: 2) {
                                    Text("AISLE")
                                        .font(.system(size: 7, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(Color.white.opacity(0.2))
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 1, height: 16)
                                }
                                .frame(width: 32)

                                HStack(spacing: 6) {
                                    ForEach(rightWing) { seat in
                                        seatButton(seat: seat, isExpanded: true)
                                    }
                                }

                                Text(row)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .frame(width: 20)
                            }
                        }
                    }
                    .padding(16)
                    .frame(minWidth: 460)
                }
                .frame(height: 280)
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        } else {
            VStack(spacing: 8) {
                ForEach(sortedRowLabels, id: \.self) { row in
                    let rowSeats = (groupedRows[row] ?? []).sorted(by: { $0.seatNumber < $1.seatNumber })
                    let half = max(1, rowSeats.count / 2)
                    let leftWing = Array(rowSeats.prefix(half))
                    let rightWing = Array(rowSeats.dropFirst(half))

                    HStack(spacing: 5) {
                        Text(row)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .frame(width: 14)

                        HStack(spacing: 5) {
                            ForEach(leftWing) { seat in
                                seatButton(seat: seat, isExpanded: false)
                            }
                        }

                        // Compact Center Aisle Gap
                        Spacer().frame(width: 12)

                        HStack(spacing: 5) {
                            ForEach(rightWing) { seat in
                                seatButton(seat: seat, isExpanded: false)
                            }
                        }

                        Text(row)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .frame(width: 14)
                    }
                }
            }
        }
    }

    private func seatButton(seat: Seat, isExpanded: Bool) -> some View {
        let isBooked = bookedSeatIDs.contains(seat.id)
        let isHeld = heldSeatIDs.contains(seat.id)
        let isSelected = selectedSeats.contains(seat)

        return CinemaSeatButton(
            seat: seat,
            isSelected: isSelected,
            isBooked: isBooked,
            isHeld: isHeld,
            isExpanded: isExpanded
        ) {
            guard !isBooked && !isHeld else { return }
            if isSelected {
                selectedSeats.remove(seat)
            } else {
                selectedSeats.insert(seat)
            }
            onSelect?(seat)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
