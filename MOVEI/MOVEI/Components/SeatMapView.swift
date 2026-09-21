//
//  SeatMapView.swift
//  MOVEI
//

import SwiftUI

public struct SeatMapView: View {
    public let seats: [Seat]
    @Binding public var selectedSeats: Set<Seat>
    public let bookedSeatIDs: Set<String>
    public let heldSeatIDs: Set<String>
    public var onSelect: ((Seat) -> Void)?

    public init(
        seats: [Seat],
        selectedSeats: Binding<Set<Seat>>,
        bookedSeatIDs: Set<String> = [],
        heldSeatIDs: Set<String> = [],
        onSelect: ((Seat) -> Void)? = nil
    ) {
        self.seats = seats
        self._selectedSeats = selectedSeats
        self.bookedSeatIDs = bookedSeatIDs
        self.heldSeatIDs = heldSeatIDs
        self.onSelect = onSelect
    }

    private var groupedRows: [String: [Seat]] {
        Dictionary(grouping: seats, by: { $0.rowLabel })
    }

    private var sortedRowLabels: [String] {
        groupedRows.keys.sorted()
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Cinema Screen curve banner
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(colors: [AppTheme.lime.opacity(0.8), AppTheme.brand.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 5)
                    .shadow(color: AppTheme.lime.opacity(0.5), radius: 8, y: 2)

                Text("CINEMA SCREEN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 8)

            // Seat grid
            VStack(spacing: 8) {
                ForEach(sortedRowLabels, id: \.self) { row in
                    HStack(spacing: 8) {
                        Text(row)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.muted)
                            .frame(width: 18)

                        let rowSeats = (groupedRows[row] ?? []).sorted(by: { $0.seatNumber < $1.seatNumber })
                        ForEach(rowSeats) { seat in
                            let isBooked = bookedSeatIDs.contains(seat.id)
                            let isHeld = heldSeatIDs.contains(seat.id)
                            let isSelected = selectedSeats.contains(seat)

                            Button {
                                guard !isBooked && !isHeld else { return }
                                if isSelected {
                                    selectedSeats.remove(seat)
                                } else {
                                    selectedSeats.insert(seat)
                                }
                                onSelect?(seat)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text("\(seat.seatNumber)")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(seatColor(isSelected: isSelected, isBooked: isBooked, isHeld: isHeld, type: seat.seatType))
                                    .foregroundStyle(isSelected ? AppTheme.ink : (isBooked ? Color.white.opacity(0.3) : AppTheme.ink))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(isBooked || isHeld)
                        }

                        Text(row)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.muted)
                            .frame(width: 18)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .white, label: "Available")
                LegendItem(color: AppTheme.lime, label: "Selected")
                LegendItem(color: Color.gray.opacity(0.3), label: "Sold")
                LegendItem(color: Color.orange.opacity(0.4), label: "Held")
            }
            .padding(.top, 10)
        }
    }

    private func seatColor(isSelected: Bool, isBooked: Bool, isHeld: Bool, type: SeatType) -> Color {
        if isSelected { return AppTheme.lime }
        if isBooked { return Color.gray.opacity(0.2) }
        if isHeld { return Color.orange.opacity(0.3) }
        switch type {
        case .vip: return Color.purple.opacity(0.18)
        case .premium: return Color.blue.opacity(0.15)
        case .standard, .disabled: return Color.white
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
    }
}
