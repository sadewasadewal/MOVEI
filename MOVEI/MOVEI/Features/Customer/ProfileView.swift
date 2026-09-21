//
//  ProfileView.swift
//  MOVEI
//

import SwiftUI

public struct ProfileView: View {
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var ticketService = TicketService.shared
    @ObservedObject private var movieService = MovieService.shared
    @State private var showWatchedSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar & Info
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.ink)
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(AppTheme.lime)
                        }

                        VStack(spacing: 4) {
                            Text(auth.currentUser?.fullName ?? "Customer")
                                .font(.title3.weight(.bold))

                            HStack(spacing: 6) {
                                Image(systemName: auth.currentRole.badgeIcon)
                                Text(auth.currentRole.title.uppercased())
                            }
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.4)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.lime, in: Capsule())
                        }
                    }
                    .padding(.top, 14)

                    // Stats row
                    HStack(spacing: 12) {
                        ProfileStatTile(value: "\(ticketService.upcomingTickets.count)", title: "Active Passes")
                        Button {
                            showWatchedSheet = true
                        } label: {
                            ProfileStatTile(value: "\(ticketService.watchedTickets.count)", title: "Watched ↗")
                        }
                        .buttonStyle(.plain)
                        ProfileStatTile(value: "3", title: "Cinemas")
                    }
                    .padding(.horizontal, 20)

                    // Admin Studio Sync Status & Control
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEB ADMIN STUDIO SYNC")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Admin Connection")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text(movieService.syncStatusMessage)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                Circle()
                                    .fill(movieService.isLoading ? Color.orange : AppTheme.lime)
                                    .frame(width: 10, height: 10)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Active Host")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.muted)
                                TextField("e.g. Sandews-MacBook-Air.local:3000", text: $movieService.customServerHost)
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(10)
                                    .background(AppTheme.canvas)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Button {
                                Task {
                                    await movieService.fetchMoviesFromBackend()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: movieService.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                    Text(movieService.isLoading ? "Syncing with Admin..." : "Sync Movies Now (\(movieService.publishedMovies.count) Live)")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(AppTheme.lime)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                movieService.clearCacheAndReload()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Cache & Reload")
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.muted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(AppTheme.canvas)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal, 20)

                    // Role Switcher for seamless testing across personas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SWITCH ROLE / PERSONA")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        VStack(spacing: 1) {
                            RoleRow(title: "Customer Persona", subtitle: "Book tickets, wallet, collectibles", role: .customer, current: auth.currentRole)
                            Divider()
                            RoleRow(title: "Cinema Scanner Staff", subtitle: "Camera scanner, ticket verification", role: .scanner, current: auth.currentRole)
                            Divider()
                            RoleRow(title: "Platform Administrator", subtitle: "KPIs, movie publishing, shows, cinemas", role: .admin, current: auth.currentRole)
                        }
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal, 20)

                    // Sign Out
                    Button {
                        auth.signOut()
                    } label: {
                        Text("Sign Out")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 110)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $showWatchedSheet) {
                WatchedView()
            }
        }
    }
}

private struct ProfileStatTile: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct RoleRow: View {
    let title: String
    let subtitle: String
    let role: UserRole
    let current: UserRole

    var body: some View {
        Button {
            AuthService.shared.updateRole(to: role)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                if role == current {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.lime)
                }
            }
            .padding(14)
        }
    }
}
