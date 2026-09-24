//
//  LottieAnimationView.swift
//  MOVEI
//

import SwiftUI
import WebKit

/// A hardware-accelerated, monochrome-styled Lottie / Vector Animation Player
/// Displays an animated cinema ticket pass with glowing scan lines, holographic sheen, and floating dynamics.
public struct LottieAnimationView: View {
    public let lottieURL: URL?
    public let loop: Bool

    @State private var isFloating = false
    @State private var shineOffset: CGFloat = -180
    @State private var scanLineOffset: CGFloat = -35
    @State private var pulseGlow: CGFloat = 0.5

    public init(
        lottieURL: URL? = nil,
        loop: Bool = true
    ) {
        self.lottieURL = lottieURL
        self.loop = loop
    }

    public var body: some View {
        ZStack {
            if let url = lottieURL {
                LottieWebView(url: url, loop: loop)
                    .allowsHitTesting(false)
            } else {
                // High-fidelity Animated Monochrome Cinema Ticket Pass
                MonochromeCinemaTicketView(
                    isFloating: isFloating,
                    shineOffset: shineOffset,
                    scanLineOffset: scanLineOffset,
                    pulseGlow: pulseGlow
                )
                .onAppear {
                    // Gentle floating
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        isFloating = true
                    }
                    // Holographic sheen sweeping across ticket
                    withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: false)) {
                        shineOffset = 220
                    }
                    // Barcode laser scanner sweeping horizontally
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        scanLineOffset = 35
                    }
                    // Ambient pulse
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        pulseGlow = 1.0
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 145)
    }
}

/// Custom Ticket Notch Shape
public struct CinemaTicketShape: Shape {
    public var cornerRadius: CGFloat = 16
    public var notchRadius: CGFloat = 10

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top-left to Top-right
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge with center semi-circle cutout notch
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - notchRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX, y: rect.midY),
            radius: notchRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge with center semi-circle cutout notch
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + notchRadius))
        path.addArc(
            center: CGPoint(x: rect.minX, y: rect.midY),
            radius: notchRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

/// Native 120fps Monochrome Cinema Ticket Animation
public struct MonochromeCinemaTicketView: View {
    let isFloating: Bool
    let shineOffset: CGFloat
    let scanLineOffset: CGFloat
    let pulseGlow: CGFloat

    public var body: some View {
        ZStack {
            // Ambient Ticket Glow behind the card
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08 * pulseGlow))
                .frame(width: 320, height: 130)
                .blur(radius: 18)

            // The Ticket Pass Card
            ZStack {
                // Base Dark Card Background
                CinemaTicketShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.14),
                                Color(white: 0.08),
                                Color(white: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Crisp Monochromatic Border Outline
                CinemaTicketShape()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1.2)

                // Content inside ticket
                HStack(spacing: 0) {
                    
                    // Left Section: Admission Stub
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 3) {
                            Text("★")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.white)
                            Text("ADMIT")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1.5)
                                .foregroundStyle(Color.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ROW")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Text("VIP")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Color.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SEAT")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Text("01")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .frame(width: 68)
                    .padding(.leading, 18)

                    // Vertical Perforated Tear Line
                    VStack(spacing: 4) {
                        ForEach(0..<13) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 2, height: 2)
                        }
                    }
                    .padding(.horizontal, 8)

                    // Right Section: Ticket Details & Animated Barcode
                    VStack(alignment: .leading, spacing: 7) {
                        
                        // Header Row
                        HStack {
                            Text("MOVEI CINEMA PASS")
                                .font(.system(size: 10, weight: .black))
                                .tracking(2.2)
                                .foregroundStyle(Color.white)

                            Spacer()

                            // Live Indicator Tag
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                                    .shadow(color: .white, radius: 3)
                                Text("VALID")
                                    .font(.system(size: 8, weight: .black))
                                    .tracking(1)
                                    .foregroundStyle(Color.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Text("HALL 01 • DOLBY ATMOS & IMAX")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Color.white.opacity(0.55))

                        // Animated Barcode with Sweeping Laser Scan Line
                        ZStack {
                            // Barcode Lines
                            HStack(spacing: 2.2) {
                                ForEach(0..<28) { i in
                                    Rectangle()
                                        .fill(Color.white.opacity(i % 3 == 0 ? 0.9 : 0.45))
                                        .frame(width: i % 4 == 0 ? 3.5 : (i % 2 == 0 ? 1.5 : 2), height: 22)
                                }
                            }

                            // Sweeping Laser Light Bar
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.9),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 14, height: 26)
                                .offset(x: scanLineOffset)
                                .shadow(color: .white, radius: 5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)

                        // Bottom Pass Code
                        HStack {
                            Text("NO. 892-410-MOV")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.7))

                            Spacer()

                            Text("DIGITAL TICKET")
                                .font(.system(size: 7, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                    }
                    .padding(.trailing, 18)
                    .padding(.leading, 6)
                }

                // Holographic Diagonal Sheen Beam that sweeps across the whole ticket
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.18), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 160)
                    .rotationEffect(.degrees(25))
                    .offset(x: shineOffset)
                    .mask(CinemaTicketShape())
            }
            .frame(width: 320, height: 122)
            .offset(y: isFloating ? -4 : 4)
        }
    }
}

/// WebKit-backed Lottie WebView Renderer for external .lottie or .json URLs
public struct LottieWebView: UIViewRepresentable {
    public let url: URL
    public let loop: Bool

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        loadAnimation(in: webView)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadAnimation(in webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { margin:0; padding:0; box-sizing: border-box; }
            body, html { width:100%; height:100%; overflow:hidden; background:transparent; display:flex; align-items:center; justify-content:center; }
            #lottie-box { width: 100%; height: 100%; }
          </style>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js"></script>
        </head>
        <body>
          <div id="lottie-box"></div>
          <script>
            try {
              lottie.loadAnimation({
                container: document.getElementById('lottie-box'),
                renderer: 'svg',
                loop: \(loop ? "true" : "false"),
                autoplay: true,
                path: '\(url.absoluteString)'
              });
            } catch(e) {
              console.error(e);
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
