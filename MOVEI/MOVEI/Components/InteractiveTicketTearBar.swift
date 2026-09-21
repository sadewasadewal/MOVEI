//
//  InteractiveTicketTearBar.swift
//  MOVEI
//

import SwiftUI
import UIKit

public struct InteractiveTicketTearBar: View {
    @Binding public var isTorn: Bool
    public var onTear: (() -> Void)? = nil
    @State private var dragX: CGFloat = 0
    @State private var lastHapticThreshold: Int = 0

    public init(isTorn: Binding<Bool>, onTear: (() -> Void)? = nil) {
        self._isTorn = isTorn
        self.onTear = onTear
    }

    public var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)

            ZStack {
                Color.white

                // Notch cutouts on left and right edges
                HStack(spacing: 0) {
                    Circle().fill(AppTheme.canvas)
                        .frame(width: 20, height: 20)
                        .offset(x: -10)
                    Spacer()
                    Circle().fill(AppTheme.canvas)
                        .frame(width: 20, height: 20)
                        .offset(x: 10)
                }

                if !isTorn {
                    // Clean dotted perforation stitches
                    HStack(spacing: 5) {
                        ForEach(0..<Int(width / 10), id: \.self) { i in
                            let dotX = CGFloat(i) * 10
                            let isCut = dotX < dragX
                            Circle()
                                .fill(isCut ? Color.red.opacity(0.45) : AppTheme.muted.opacity(0.35))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        guard !isTorn else { return }
                        dragX = max(0, value.location.x)
                        let currentStep = Int((dragX / width) * 18)
                        if currentStep != lastHapticThreshold && currentStep >= 0 {
                            lastHapticThreshold = currentStep
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
                        }
                    }
                    .onEnded { value in
                        guard !isTorn else { return }
                        let finalProgress = dragX / width
                        if finalProgress > 0.5 || value.predictedEndLocation.x > width * 0.6 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragX = width
                                isTorn = true
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
                            onTear?()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                dragX = 0
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        lastHapticThreshold = 0
                    }
            )
        }
        .frame(height: 24)
        .clipped()
        .onChange(of: isTorn) { _, newValue in
            if !newValue {
                // Snap-back: rebuild the perforations with a spring
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    dragX = 0
                }
                lastHapticThreshold = 0
            }
        }
    }
}
