//
//  WalletView.swift
//  MOVEI
//

import SwiftUI
import SwiftData

public struct WalletView: View {
    @ObservedObject private var ticketService = TicketService.shared
    @Environment(\.modelContext) private var modelContext
    public let onTicket: (Ticket) -> Void
    @State private var selectedIndex = 0
    @State private var showClearConfirmation = false

    public init(onTicket: @escaping (Ticket) -> Void) {
        self.onTicket = onTicket
    }

    private var tickets: [Ticket] {
        ticketService.upcomingTickets
    }

    private var activeIndex: Int {
        guard !tickets.isEmpty else { return 0 }
        return min(max(selectedIndex, 0), tickets.count - 1)
    }

    private var activeTicket: Ticket? {
        guard !tickets.isEmpty else { return nil }
        return tickets[activeIndex]
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header with Three-Dots Pass Management
                    HStack(alignment: .firstTextBaseline) {
                        Text("Your Tickets")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                        Menu {
                            if let current = activeTicket {
                                Button(role: .destructive) {
                                    deleteTicket(current)
                                } label: {
                                    Label("Delete Active Pass (\(current.movieTitle))", systemImage: "trash")
                                }
                            }
                            if !tickets.isEmpty {
                                Button(role: .destructive) {
                                    showClearConfirmation = true
                                } label: {
                                    Label("Clear All Passes (\(tickets.count))", systemImage: "trash.fill")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundStyle(AppTheme.ink)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .confirmationDialog("Clear All Passes?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                            Button("Delete All \(tickets.count) Passes", role: .destructive) {
                                clearAllTickets()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will permanently remove all movie passes from your wallet.")
                        }
                    }

                    // Section header with passes count pill
                    HStack(alignment: .center) {
                        Text("YOUR PASSES")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.muted)
                        Spacer()
                        if !tickets.isEmpty {
                            Text("\(tickets.count) PASS\(tickets.count == 1 ? "" : "ES")")
                                .font(.caption2.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.surfaceElevated, in: Capsule())
                        }
                    }

                    if tickets.isEmpty {
                        EmptyWalletCard()
                    } else if let currentTicket = activeTicket {
                        // Stacked 3D Pass Deck
                        VStack(spacing: 20) {
                            ZStack(alignment: .bottom) {
                                ForEach(peekIndices(), id: \.self) { idx in
                                    let peekTicket = tickets[idx]
                                    let level = peekLevel(for: idx)
                                    WalletPeekCard(ticket: peekTicket)
                                        .offset(y: -CGFloat(level + 1) * 34)
                                        .scaleEffect(1.0 - CGFloat(level + 1) * 0.03)
                                        .zIndex(Double(3 - level))
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                                selectedIndex = idx
                                            }
                                        }
                                }

                                WalletTicketCard(ticket: currentTicket)
                                    .zIndex(10)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onTicket(currentTicket)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 30)
                                            .onEnded { value in
                                                if value.translation.width < -40 {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                                        selectedIndex = (activeIndex + 1) % tickets.count
                                                    }
                                                } else if value.translation.width > 40 {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                                        selectedIndex = (activeIndex - 1 + tickets.count) % tickets.count
                                                    }
                                                }
                                            }
                                    )
                            }
                            .padding(.top, CGFloat(peekCount) * 34)
                        }

                        // All Passes List
                        if tickets.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ALL PASSES")
                                    .font(.caption.weight(.bold))
                                    .tracking(1.4)
                                    .foregroundStyle(AppTheme.muted)
                                    .padding(.top, 12)

                                ForEach(Array(tickets.enumerated()), id: \.element.id) { index, ticket in
                                    WalletMiniCard(ticket: ticket)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(index == activeIndex ? AppTheme.ink : Color.clear, lineWidth: 2)
                                        )
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteTicket(ticket)
                                            } label: {
                                                Label("Delete Pass", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                                selectedIndex = index
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 110)
            }
            .background(.ultraThinMaterial)
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var peekCount: Int {
        min(tickets.count - 1, 2)
    }

    private func peekIndices() -> [Int] {
        guard tickets.count > 1 else { return [] }
        var indices: [Int] = []
        for offset in 1...peekCount {
            let idx = (activeIndex + offset) % tickets.count
            indices.append(idx)
        }
        return indices.reversed()
    }

    private func peekLevel(for index: Int) -> Int {
        guard let pos = peekIndices().firstIndex(of: index) else { return 0 }
        return pos
    }

    private func deleteTicket(_ ticket: Ticket) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            ticketService.deleteTicket(ticket)
            let remaining = ticketService.upcomingTickets.count
            if remaining <= 1 {
                selectedIndex = 0
            } else if selectedIndex >= remaining {
                selectedIndex = remaining - 1
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func clearAllTickets() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            ticketService.clearAllTickets()
            selectedIndex = 0
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

public struct EmptyWalletCard: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "ticket")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.muted)
            Text("No Upcoming Passes")
                .font(.headline)
            Text("When you book cinema tickets, your passes will appear right here.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
