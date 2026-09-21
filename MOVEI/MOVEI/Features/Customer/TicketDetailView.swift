//
//  TicketDetailView.swift
//  MOVEI
//

import SwiftUI

public struct TicketDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let ticket: Ticket
    public let onDone: () -> Void

    // Live Tearing & Status States
    @State private var isTorn: Bool
    @State private var tearOffset: CGFloat = 0
    @State private var tearRotation: Double = 0
    @State private var showAdmittedStamp: Bool = false
    @State private var liveAdmissionToast: String? = nil
    @State private var asmrToast: String? = nil
    @State private var scannedAtDate: Date?
    @State private var scannedByStaff: String?

    public init(ticket: Ticket, onDone: @escaping () -> Void) {
        self.ticket = ticket
        self.onDone = onDone
        let isAlreadyUsed = ticket.status == "used" || ticket.status == "torn"
        self._isTorn = State(initialValue: isAlreadyUsed)
        self._showAdmittedStamp = State(initialValue: isAlreadyUsed)
        self._tearOffset = State(initialValue: isAlreadyUsed ? 20 : 0)
        self._tearRotation = State(initialValue: isAlreadyUsed ? -2.2 : 0)
        self._scannedAtDate = State(initialValue: ticket.scannedAt)
        self._scannedByStaff = State(initialValue: ticket.scannedBy)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Fixed Top Navigation Bar with proper touch targets and safe clearance
            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                    onDone()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                        Text("Wallet")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface, in: Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Go back to Wallet")

                Spacer()

                Menu {
                    Button {
                        UIPasteboard.general.string = ticket.ticketCode
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Copy Code: \(ticket.ticketCode)", systemImage: "doc.on.doc")
                    }

                    if !isTorn {
                        Button {
                            triggerASMRTearAndRepaste()
                        } label: {
                            Label("Feel the Tear ✨ (ASMR)", systemImage: "scissors")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.surface, in: Circle())
                        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Ticket options")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(AppTheme.canvas)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Live Admission Banner when ticket is torn
                    if let toast = liveAdmissionToast {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.success)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(toast)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Admitted by \(scannedByStaff ?? "Cinema Staff") • Enjoy your movie!")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.success.opacity(0.35), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Guidance hint for attendee
                    if !isTorn {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppTheme.lime)
                                .frame(width: 8, height: 8)
                            Text("Present barcode to cinema staff for scanning")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.muted)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }

                    // The Ticket Assembly
                    VStack(spacing: 0) {
                        // TOP HALF: Movie Pass
                        VStack(spacing: 0) {
                            ZStack(alignment: .top) {
                                TicketPassArtworkView(ticket: ticket)

                                LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .center)

                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("MOVEI").font(.title3.weight(.black))
                                        Text("CINEMA").font(.caption2.weight(.bold)).tracking(1.8)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(ticket.showtime, format: .dateTime.month(.abbreviated).day()).font(.headline.weight(.bold))
                                        Text(ticket.showtime, format: .dateTime.hour().minute()).font(.subheadline.weight(.semibold))
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(20)
                            }

                            ZStack(alignment: .bottomLeading) {
                                AppTheme.passBackground
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(ticket.movieTitle).font(.system(size: 28, weight: .bold))
                                    HStack(alignment: .bottom) {
                                        PassDetail(label: "VENUE", value: ticket.cinemaName, lightText: true)
                                        Spacer()
                                        PassDetail(label: "SCREEN", value: ticket.screenName, lightText: true)
                                        PassDetail(label: "SEATS", value: ticket.seatLabel, lightText: true)
                                    }
                                }
                                .padding(22)
                            }
                            .frame(height: 142)
                            .foregroundStyle(.white)

                            // Dotted Perforation Bar with interactive touch tear (ASMR only - no backend)
                            InteractiveTicketTearBar(isTorn: $isTorn) {
                                triggerASMRTearAndRepaste()
                            }
                        }
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 25,
                                bottomLeadingRadius: isTorn ? 16 : 0,
                                bottomTrailingRadius: isTorn ? 16 : 0,
                                topTrailingRadius: 25
                            )
                        )
                        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)

                        // BOTTOM STUB: Barcode section that detaches and tears
                        VStack(spacing: 12) {
                            ZStack {
                                VStack(spacing: 12) {
                                    BarcodeView(value: ticket.barcodeValue)
                                        .frame(height: 128)
                                        .accessibilityLabel("Barcode for ticket \(ticket.ticketCode)")
                                    Text(ticket.ticketCode)
                                        .font(.caption.monospaced().weight(.semibold))
                                        .foregroundStyle(Color.black.opacity(0.65))
                                }
                                .opacity(isTorn ? 0.35 : 1.0)

                                // TORN & ADMITTED Ink Stamp Slammed Down
                                if showAdmittedStamp {
                                    VStack(spacing: 3) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "scissors")
                                            Text("TORN & ADMITTED")
                                        }
                                        .font(.system(size: 19, weight: .black))
                                        .tracking(2)

                                        Text("\((scannedAtDate ?? Date()).formatted(date: .abbreviated, time: .shortened)) · \(scannedByStaff ?? "Staff Scanner")")
                                            .font(.system(size: 9, weight: .bold))
                                            .tracking(0.8)
                                    }
                                    .foregroundStyle(Color.red.opacity(0.92))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.92), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                    )
                                    .rotationEffect(.degrees(-6))
                                    .scaleEffect(showAdmittedStamp ? 1.0 : 1.35)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }

                            // ASMR Tear hint (no backend) + toast feedback
                            if !isTorn {
                                Button {
                                    triggerASMRTearAndRepaste()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "scissors")
                                        Text("Slide to Tear ✨ Snaps Back!")
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.muted)
                                    .padding(.vertical, 4)
                                }
                            }

                            // ASMR toast overlay
                            if let toast = asmrToast {
                                Text(toast)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.72), in: Capsule())
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                        .background(.white)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: isTorn ? 16 : 0,
                                bottomLeadingRadius: 25,
                                bottomTrailingRadius: 25,
                                topTrailingRadius: isTorn ? 16 : 0
                            )
                        )
                        .offset(y: tearOffset)
                        .rotationEffect(.degrees(tearRotation))
                        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isTorn)

                    // Additional Info Tiles
                    VStack(spacing: 0) {
                        PassActionRow(title: "Additional Ticket Info", subtitle: "Cinema entry & booking details", icon: "chevron.right")
                        HStack(spacing: 12) {
                            PassActionTile(title: "Venue", subtitle: "Open in Maps", icon: "mappin.and.ellipse")
                            PassActionTile(title: "Movie", subtitle: "View details", icon: "film")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .task {
                // Live Polling for Real-Time Cinema Staff Scan
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(1400))
                    await pollAdmissionStatus()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.height > 80 && abs(value.translation.width) < 60 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                            onDone()
                        }
                    }
            )
        }
    }

    // ASMR tear for customers: rips then magnetically snaps back. No backend call.
    private func triggerASMRTearAndRepaste() {
        guard !isTorn else { return }

        // Phase 1: Dramatic rip with heavy + rigid haptics
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) {
            isTorn = true
            tearOffset = 26
            tearRotation = -2.8
        }
        withAnimation(.easeIn(duration: 0.05).delay(0.05)) { asmrToast = "✂️ Ripping..." }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)

        // Phase 2: Additional ASMR crinkle haptics
        Task {
            for delay in [90, 155, 210] {
                try? await Task.sleep(for: .milliseconds(delay))
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
            }
        }

        // Phase 3: Magnetic snap-back after ~0.75s
        Task {
            try? await Task.sleep(for: .milliseconds(760))
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                isTorn = false
                tearOffset = 0
                tearRotation = 0
            }
            try? await Task.sleep(for: .milliseconds(60))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.85)
            withAnimation(.easeIn(duration: 0.05)) { asmrToast = "🔒 Snapped back — scan to admit" }
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation { asmrToast = nil }
        }
    }

    // Staff-scanner triggered permanent admission (called only via pollAdmissionStatus)
    private func triggerLiveTear(scannedAt: Date, staff: String) {
        guard !isTorn else { return }
        self.scannedAtDate = scannedAt
        self.scannedByStaff = staff

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            isTorn = true
            tearOffset = 20
            tearRotation = -2.2
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.bouncy(duration: 0.35)) {
                showAdmittedStamp = true
                liveAdmissionToast = "Ticket Admitted by Cinema Staff!"
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func pollAdmissionStatus() async {
        guard !isTorn else { return }

        // Check local service update first
        if let local = TicketService.shared.tickets.first(where: {
            $0.ticketCode == ticket.ticketCode || $0.barcodeValue == ticket.barcodeValue
        }) {
            if (local.status == "used" || local.status == "torn") && !isTorn {
                triggerLiveTear(scannedAt: local.scannedAt ?? Date(), staff: local.scannedBy ?? "Staff Scanner")
                return
            }
        }

        // Query Web Admin REST API
        let baseURL = MovieService.shared.activeBaseURL
        guard let encoded = ticket.ticketCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/tickets?code=\(encoded)") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let item = json["ticket"] as? [String: Any] {
                let status = item["status"] as? String ?? ""
                let torn = item["torn"] as? Bool ?? false
                if (status == "used" || torn) && !isTorn {
                    let staff = item["scanned_by"] as? String ?? "Staff Scanner"
                    triggerLiveTear(scannedAt: Date(), staff: staff)
                }
            }
        } catch {
            // Background check offline
        }
    }
}

public struct TicketPassArtworkView: View {
    public let ticket: Ticket

    public var body: some View {
        RobustAsyncImage(candidateURLs: ticketArtworkCandidates(ticket)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            AppTheme.passBackground
        }
        .frame(height: 380)
        .clipped()
    }
}
