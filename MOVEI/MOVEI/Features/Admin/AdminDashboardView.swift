//
//  AdminDashboardView.swift
//  MOVEI
//

import SwiftUI

public struct AdminDashboardView: View {
    @ObservedObject private var movieService = MovieService.shared
    @ObservedObject private var showService = ShowService.shared
    @ObservedObject private var scannerService = ScannerService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MOVEI ADMIN")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundStyle(AppTheme.muted)
                        Text("Platform Overview")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // 4 Core KPI Cards
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                        AdminKPICard(title: "Tickets Sold", value: "428", icon: "ticket.fill", color: .blue)
                        AdminKPICard(title: "Today's Revenue", value: "Rs. 428,000", icon: "banknote.fill", color: .green)
                        AdminKPICard(title: "Shows Today", value: "\(showService.shows.count)", icon: "film.fill", color: .purple)
                        AdminKPICard(title: "Admissions", value: "\(scannerService.totalAdmissionsToday)", icon: "checkmark.seal.fill", color: .orange)
                    }
                    .padding(.horizontal, 20)

                    // Quick Management Shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MANAGEMENT MODULES")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        VStack(spacing: 1) {
                            AdminModuleRow(title: "Movies Catalog", count: "\(movieService.movies.count) movies", icon: "film")
                            Divider()
                            AdminModuleRow(title: "Show Scheduling", count: "\(showService.shows.count) scheduled", icon: "calendar")
                            Divider()
                            AdminModuleRow(title: "Cinemas & Screens", count: "3 Cinemas · 3 Screens", icon: "building.2")
                            Divider()
                            AdminModuleRow(title: "Scanner Staff", count: "4 active staff", icon: "qrcode.viewfinder")
                        }
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal, 20)

                    // Recent Admission Audits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT SCAN ACTIVITY")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        ForEach(scannerService.recentScans.prefix(3)) { scan in
                            HStack {
                                Image(systemName: scan.result == "valid" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(scan.result == "valid" ? AppTheme.success : AppTheme.danger)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scan.ticketCode)
                                        .font(.caption.monospaced().weight(.bold))
                                    Text("\(scan.movieTitle ?? "Unknown Movie") · \(scan.result.uppercased())")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                Text(scan.scannedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct AdminKPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

private struct AdminModuleRow: View {
    let title: String
    let count: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(count)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(14)
    }
}
