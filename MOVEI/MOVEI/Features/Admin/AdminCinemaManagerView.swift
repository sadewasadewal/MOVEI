//
//  AdminCinemaManagerView.swift
//  MOVEI
//

import SwiftUI

public struct AdminCinemaManagerView: View {
    @ObservedObject private var cinemaService = CinemaService.shared
    @State private var selectedScreen: Screen?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(cinemaService.cinemas) { cinema in
                    Section(cinema.name) {
                        Text(cinema.address)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)

                        let screens = cinemaService.screens(for: cinema.id)
                        ForEach(screens) { screen in
                            Button {
                                selectedScreen = screen
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(screen.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.ink)
                                        Text("Capacity: \(screen.capacity) seats · \(screen.screenType.uppercased())")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                    Text("Edit Layout")
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.brand)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cinemas & Screens")
            .sheet(item: $selectedScreen) { screen in
                AdminVisualSeatEditorView(screen: screen)
            }
        }
    }
}

public struct AdminVisualSeatEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cinemaService = CinemaService.shared
    public let screen: Screen
    @State private var dummySelected: Set<Seat> = []

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Visual Seat Layout Editor")
                            .font(.headline)
                        Text("\(screen.name) (Capacity: \(screen.capacity))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.top, 16)

                    let screenSeats = cinemaService.seats(for: screen.id)
                    SeatMapView(seats: screenSeats, selectedSeats: $dummySelected)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("TIER CONFIGURATION")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.muted)

                        HStack {
                            Text("Rows A - B")
                            Spacer()
                            Text("Standard Tier")
                                .font(.caption.bold())
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        HStack {
                            Text("Row C")
                            Spacer()
                            Text("Premium Tier")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        HStack {
                            Text("Rows D - E")
                            Spacer()
                            Text("VIP Recliner Tier")
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
