//
//  ScannerDashboardView.swift
//  MOVEI
//

import SwiftUI

public struct ScannerDashboardView: View {
    @ObservedObject private var scannerService = ScannerService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STAFF ACCESS")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)
                        Text(scannerService.assignedCinema.name)
                            .font(.system(size: 28, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Admissions Today Stat Card
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ADMISSIONS TODAY")
                                .font(.caption.bold())
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.muted)
                            Text("\(scannerService.totalAdmissionsToday)")
                                .font(.system(size: 38, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                            Text("Across all screening gates")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.lime)
                    }
                    .padding(20)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal, 20)

                    // Scan history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT SCANS")
                            .font(.caption.bold())
                            .tracking(1.4)
                            .foregroundStyle(AppTheme.muted)

                        ForEach(scannerService.recentScans) { scan in
                            HStack(spacing: 12) {
                                Image(systemName: scan.result == "valid" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(scan.result == "valid" ? AppTheme.success : AppTheme.danger)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scan.ticketCode)
                                        .font(.subheadline.monospaced().weight(.bold))
                                    Text("\(scan.movieTitle ?? "Cinema Pass") · Seat \(scan.seat ?? "--")")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(scan.result.uppercased())
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(scan.result == "valid" ? AppTheme.success : AppTheme.danger)
                                    Text(scan.scannedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.muted)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Scanner Activity")
        }
    }
}

public struct ScannerRootView: View {
    public init() {}

    public var body: some View {
        TabView {
            ScannerCameraView()
                .tabItem { Label("Scan Ticket", systemImage: "qrcode.viewfinder") }

            ScannerDashboardView()
                .tabItem { Label("Activity", systemImage: "clock.arrow.circlepath") }

            ProfileView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .tint(AppTheme.ink)
    }
}
