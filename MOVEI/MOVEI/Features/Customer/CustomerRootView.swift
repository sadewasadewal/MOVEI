//
//  CustomerRootView.swift
//  MOVEI
//

import SwiftUI

public struct CustomerRootView: View {
    @State private var selectedTab = 0
    @State private var selectedMovie: Movie?
    @State private var showTicket: Ticket?
    @State private var showBookingMovie: Movie?

    public init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.55)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.55),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        itemAppearance.selected.iconColor = UIColor.white
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                onBook: { movie in
                    showBookingMovie = movie
                },
                onDetails: { movie in
                    selectedMovie = movie
                },
                onTicket: { showTicket = $0 }
            )
            .ignoresSafeArea(edges: .top)
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            MoviesView(onMovie: { selectedMovie = $0 })
                .tabItem { Label("Movies", systemImage: "film.fill") }
                .tag(1)

            WalletView(onTicket: { showTicket = $0 })
                .tabItem { Label("Wallet", systemImage: "wallet.pass.fill") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.white)
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(movie: movie) {
                selectedMovie = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showBookingMovie = movie
                }
            }
        }
        .sheet(item: $showBookingMovie) { movie in
            BookingView(movie: movie) { issuedTicket in
                selectedTab = 2 // Switch to Wallet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    showTicket = issuedTicket
                }
            }
        }
        .fullScreenCover(item: $showTicket) { ticket in
            TicketDetailView(ticket: ticket) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showTicket = nil
                }
            }
        }
    }
}
