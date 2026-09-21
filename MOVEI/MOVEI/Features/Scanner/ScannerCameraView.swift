//
//  ScannerCameraView.swift
//  MOVEI
//

import SwiftUI
import AVFoundation

public struct ScannerCameraView: View {
    @ObservedObject private var scannerService = ScannerService.shared
    @State private var manualBarcode = ""
    @State private var activeAdmissionResult: AdmissionResult?
    @State private var isFlashOn = false
    @State private var isVerifying = false
    @State private var isCameraScanning = true
    @State private var scanBeamOffset: CGFloat = -80
    @State private var hasCameraAccess = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Live Camera Video Feed
                BarcodeCameraScannerView(
                    isScanning: Binding(
                        get: { isCameraScanning && activeAdmissionResult == nil && !isVerifying },
                        set: { isCameraScanning = $0 }
                    ),
                    isTorchOn: $isFlashOn
                ) { scannedCode in
                    handleScannedBarcode(scannedCode)
                }
                .ignoresSafeArea()

                // Semi-translucent dark vignette overlay around viewfinder
                ViewfinderVignetteOverlay()
                    .ignoresSafeArea()

                // Overlay Controls & Viewfinder Target
                VStack(spacing: 16) {
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(AppTheme.lime)
                                    .frame(width: 8, height: 8)
                                Text("CAMERA SCANNER")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(1.8)
                                    .foregroundStyle(AppTheme.lime)
                            }
                            Text(scannerService.assignedCinema.name)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Button {
                            isFlashOn.toggle()
                        } label: {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.title3)
                                .foregroundStyle(isFlashOn ? AppTheme.lime : .white)
                                .padding(10)
                                .background(Color.black.opacity(0.6), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                    Spacer()

                    // Visual Viewfinder Frame & Animated Laser Scan Beam
                    ZStack {
                        // Viewfinder border box
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppTheme.lime, style: StrokeStyle(lineWidth: 3, dash: [36, 18]))
                            .frame(width: 290, height: 190)
                            .shadow(color: AppTheme.lime.opacity(0.3), radius: 8)

                        // Animated Laser Scanning Line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, AppTheme.lime.opacity(0.85), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 270, height: 2.5)
                            .offset(y: scanBeamOffset)
                            .shadow(color: AppTheme.lime, radius: 4)

                        // Center helper text
                        VStack(spacing: 6) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 46))
                                .foregroundStyle(AppTheme.lime.opacity(0.85))
                            Text("Align Barcode or QR within frame")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(height: 200)

                    // Verifying overlay if in-progress
                    if isVerifying {
                        HStack(spacing: 8) {
                            ProgressView().tint(Color.black)
                            Text("Verifying Ticket...")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.lime, in: Capsule())
                        .shadow(color: AppTheme.lime.opacity(0.3), radius: 8)
                    }

                    Spacer()

                    // Bottom Barcode Input & Test Shortcuts
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Enter barcode (e.g. MOV-75EB31-01)", text: $manualBarcode)
                                .padding(14)
                                .background(Color.black.opacity(0.7))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )

                            Button {
                                guard !manualBarcode.isEmpty else { return }
                                verifyTicketCode(manualBarcode)
                            } label: {
                                Text("Verify")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.black)
                                    .padding(.horizontal, 18)
                                    .frame(height: 48)
                                    .background(AppTheme.lime)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isVerifying)
                        }
                        .padding(.horizontal, 22)

                        // Quick Test simulator shortcuts
                        VStack(spacing: 6) {
                            Text("QUICK TEST SIMULATOR CODES")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.white.opacity(0.5))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button("Wicked Pass (MOV-75EB31-01)") {
                                        verifyTicketCode("MOV-75EB31-01")
                                    }
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(AppTheme.lime.opacity(0.25))
                                    .foregroundStyle(AppTheme.lime)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(AppTheme.lime.opacity(0.5), lineWidth: 1))

                                    Button("Spider-Man Pass (MOV-92FA44-01)") {
                                        verifyTicketCode("MOV-92FA44-01")
                                    }
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.white.opacity(0.18))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())

                                    Button("Already Used (MOV-19FB02-01)") {
                                        verifyTicketCode("MOV-19FB02-01")
                                    }
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(AppTheme.danger.opacity(0.25))
                                    .foregroundStyle(AppTheme.danger)
                                    .clipShape(Capsule())
                                }
                                .padding(.horizontal, 22)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .sheet(item: Binding(
                get: { activeAdmissionResult != nil ? AdmissionResultWrapper(result: activeAdmissionResult!) : nil },
                set: { _ in
                    activeAdmissionResult = nil
                    isCameraScanning = true
                }
            )) { wrapper in
                ScanResultModalView(result: wrapper.result)
            }
            .onAppear {
                isCameraScanning = true
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    scanBeamOffset = 80
                }
            }
        }
    }

    private func handleScannedBarcode(_ code: String) {
        guard !isVerifying && activeAdmissionResult == nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        verifyTicketCode(code)
    }

    private func verifyTicketCode(_ code: String) {
        guard !isVerifying else { return }
        isVerifying = true
        let staff = AuthService.shared.currentUser?.fullName ?? "Staff Scanner"

        Task {
            let res = await scannerService.validateTicket(barcode: code, staffName: staff)
            isVerifying = false
            activeAdmissionResult = res
            manualBarcode = ""
        }
    }
}

// MARK: - Viewfinder Vignette Overlay
private struct ViewfinderVignetteOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let cutoutW: CGFloat = 290
            let cutoutH: CGFloat = 190
            let cutoutX = (w - cutoutW) / 2
            let cutoutY = (h - cutoutH) / 2 - 20

            Path { path in
                path.addRect(CGRect(x: 0, y: 0, width: w, height: h))
                path.addRoundedRect(
                    in: CGRect(x: cutoutX, y: cutoutY, width: cutoutW, height: cutoutH),
                    cornerSize: CGSize(width: 22, height: 22)
                )
            }
            .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
        }
    }
}

// MARK: - Barcode Camera Scanner UIViewControllerRepresentable
public protocol BarcodeScannerDelegate: AnyObject {
    func didFindBarcode(_ code: String)
}

public struct BarcodeCameraScannerView: UIViewControllerRepresentable {
    @Binding public var isScanning: Bool
    @Binding public var isTorchOn: Bool
    public var onScanned: (String) -> Void

    public init(isScanning: Binding<Bool>, isTorchOn: Binding<Bool>, onScanned: @escaping (String) -> Void) {
        self._isScanning = isScanning
        self._isTorchOn = isTorchOn
        self.onScanned = onScanned
    }

    public func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    public func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        context.coordinator.parent = self
        uiViewController.setScanning(isScanning)
        uiViewController.setTorch(isTorchOn)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, BarcodeScannerDelegate {
        var parent: BarcodeCameraScannerView
        private var lastScannedCode: String?
        private var lastScannedTime: Date = .distantPast

        init(parent: BarcodeCameraScannerView) {
            self.parent = parent
        }

        public func didFindBarcode(_ code: String) {
            guard parent.isScanning else { return }
            let now = Date()
            if code == lastScannedCode && now.timeIntervalSince(lastScannedTime) < 2.5 {
                return
            }
            lastScannedCode = code
            lastScannedTime = now
            parent.onScanned(code)
        }
    }
}

public final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    public weak var delegate: BarcodeScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.configureSession()
                    }
                }
            }
        } else if status == .authorized {
            configureSession()
        }
    }

    private func configureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            // Simulator or device with no camera available
            return
        }

        let session = AVCaptureSession()
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            let supportedTypes: [AVMetadataObject.ObjectType] = [
                .code128, .qr, .code39, .code93, .ean13, .ean8, .upce, .pdf417, .aztec, .dataMatrix
            ]
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes.filter { supportedTypes.contains($0) }
        } else {
            return
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
        }
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else { return }
        delegate?.didFindBarcode(stringValue)
    }

    public func setScanning(_ scanning: Bool) {
        guard let session = captureSession else { return }
        if scanning {
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
            }
        } else {
            if session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
            }
        }
    }

    public func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
        }
    }
}

// MARK: - Admission Result Wrapper & Result Modal View
public struct AdmissionResultWrapper: Identifiable {
    public var id: String { result.ticketCode }
    public let result: AdmissionResult
}

public struct ScanResultModalView: View {
    @Environment(\.dismiss) private var dismiss
    public let result: AdmissionResult

    // Auto-Tear Animation State
    @State private var isTorn = false
    @State private var tearOffset: CGFloat = 0
    @State private var tearRotation: Double = 0
    @State private var showAdmittedStamp = false

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if result.isValid {
                        // VALID ADMISSION: Real-Time Auto-Tear Ticket
                        VStack(spacing: 12) {
                            // Top verification pill
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppTheme.success)
                                Text("TICKET VALIDATED • AUTO-TEARING")
                                    .font(.caption2.weight(.black))
                                    .tracking(1.4)
                                    .foregroundStyle(AppTheme.success)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppTheme.success.opacity(0.12), in: Capsule())
                            .padding(.top, 16)

                            // Cinema Pass Assembly that Tears Automatically
                            VStack(spacing: 0) {
                                // TOP HALF (Main Pass)
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MOVEI CINEMA PASS")
                                                .font(.system(size: 10, weight: .black))
                                                .tracking(1.8)
                                                .foregroundStyle(AppTheme.lime)
                                            Text(result.movieTitle ?? "Cinema Admission")
                                                .font(.title3.weight(.bold))
                                                .foregroundStyle(AppTheme.ink)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "film")
                                            .font(.title2)
                                            .foregroundStyle(AppTheme.muted)
                                    }

                                    HStack {
                                        PassDetail(label: "VENUE", value: result.cinemaName ?? "Cinemax Colombo")
                                        Spacer()
                                        PassDetail(label: "SCREEN", value: result.screenName ?? "Screen 04")
                                        PassDetail(label: "SEATS", value: result.seat ?? "General")
                                    }
                                }
                                .padding(20)
                                .background(AppTheme.surface)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 20,
                                        bottomLeadingRadius: isTorn ? 14 : 0,
                                        bottomTrailingRadius: isTorn ? 14 : 0,
                                        topTrailingRadius: 20
                                    )
                                )

                                // Perforation Cut Line with Cutout Notches
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(AppTheme.canvas)
                                        .frame(width: 18, height: 18)
                                        .offset(x: -9)

                                    DashedLine()
                                        .stroke(isTorn ? Color.red.opacity(0.6) : AppTheme.muted.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                        .frame(height: 1.5)

                                    Circle()
                                        .fill(AppTheme.canvas)
                                        .frame(width: 18, height: 18)
                                        .offset(x: 9)
                                }
                                .frame(height: 18)
                                .background(AppTheme.surface)
                                .clipped()

                                // BOTTOM HALF (Barcode Stub that separates upon tear)
                                VStack(spacing: 10) {
                                    ZStack {
                                        VStack(spacing: 6) {
                                            BarcodeView(value: result.ticketCode)
                                                .frame(height: 48)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                                                .opacity(isTorn ? 0.4 : 1.0)

                                            Text(result.ticketCode)
                                                .font(.caption2.monospaced().weight(.bold))
                                                .foregroundStyle(AppTheme.muted)
                                        }

                                        // ADMITTED / TORN STAMP SLAMMED DOWN
                                        if showAdmittedStamp {
                                            VStack(spacing: 2) {
                                                HStack(spacing: 5) {
                                                    Image(systemName: "scissors")
                                                    Text("TORN & ADMITTED")
                                                }
                                                .font(.system(size: 16, weight: .black))
                                                .tracking(1.5)

                                                Text(Date().formatted(date: .omitted, time: .shortened) + " · ENTRANCE 04")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .tracking(1)
                                            }
                                            .foregroundStyle(Color.red)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 7)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.red, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                            )
                                            .rotationEffect(.degrees(-6))
                                            .scaleEffect(showAdmittedStamp ? 1.0 : 1.4)
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                                .padding(18)
                                .background(AppTheme.surface)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: isTorn ? 14 : 0,
                                        bottomLeadingRadius: 20,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: isTorn ? 14 : 0
                                    )
                                )
                                .offset(y: tearOffset)
                                .rotationEffect(.degrees(tearRotation))
                            }
                            .padding(.horizontal, 20)
                            .shadow(color: .black.opacity(0.1), radius: 12, y: 6)

                            // Web Admin Sync Confirmation Card
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.success)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Marked in Web Admin Portal")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppTheme.ink)
                                    Text("Status updated to TORN & ADMITTED in central audit logs")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }
                    } else {
                        // REJECTED / INVALID / ALREADY USED
                        VStack(spacing: 16) {
                            Image(systemName: iconName)
                                .font(.system(size: 68))
                                .foregroundStyle(statusColor)
                                .padding(.top, 32)

                            VStack(spacing: 6) {
                                Text(result.title)
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(statusColor)
                                Text(result.message)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.muted)
                                    .padding(.horizontal, 24)
                            }

                            if let movie = result.movieTitle {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("MOVIE")
                                            .font(.caption2.bold())
                                            .foregroundStyle(AppTheme.muted)
                                        Spacer()
                                        Text(movie).font(.subheadline.bold())
                                    }
                                    if let code = result.ticketCode as String? {
                                        HStack {
                                            Text("CODE")
                                                .font(.caption2.bold())
                                                .foregroundStyle(AppTheme.muted)
                                            Spacer()
                                            Text(code).font(.subheadline.monospaced().bold())
                                        }
                                    }
                                }
                                .padding(16)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Done & Scan Next Ticket")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(result.isValid ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(result.isValid ? AppTheme.lime : statusColor, in: Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Admission Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.ink)
                }
            }
            .onAppear {
                if result.isValid {
                    // Trigger Automatic Ticket Tear Sequence!
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                            isTorn = true
                            tearOffset = 20
                            tearRotation = -2.2
                        }
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

                        try? await Task.sleep(for: .milliseconds(180))
                        withAnimation(.bouncy(duration: 0.35)) {
                            showAdmittedStamp = true
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch result.statusType {
        case .valid: return AppTheme.success
        case .alreadyUsed: return AppTheme.warning
        default: return AppTheme.danger
        }
    }

    private var iconName: String {
        switch result.statusType {
        case .valid: return "checkmark.seal.fill"
        case .alreadyUsed: return "exclamationmark.triangle.fill"
        case .wrongCinema: return "building.2.crop.circle.badge.xmark"
        default: return "xmark.octagon.fill"
        }
    }
}
