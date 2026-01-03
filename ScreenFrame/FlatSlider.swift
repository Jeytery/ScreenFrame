//
//  FlatSlider.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI
import AppKit

struct FlatSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    private let knobSize: CGFloat = 16
    private let trackHeight: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            let progress = progressFraction()
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: trackHeight)
                Capsule(style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: proxy.size.width * progress, height: trackHeight)
                Circle()
                    .fill(Color(.windowBackgroundColor))
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: proxy.size.width * progress - knobSize / 2)
            }
            .frame(height: max(knobSize, trackHeight))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = min(max(gesture.location.x, 0), proxy.size.width)
                        let rawPercent = clampedX / max(proxy.size.width, 1)
                        updateValue(percent: rawPercent)
                    }
            )
        }
        .frame(height: 24)
    }

    private func progressFraction() -> CGFloat {
        guard range.upperBound > range.lowerBound else { return 0 }
        let portion = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(min(max(portion, 0), 1))
    }

    private func updateValue(percent: CGFloat) {
        let rawValue = range.lowerBound + Double(percent) * (range.upperBound - range.lowerBound)
        let stepped = steppedValue(rawValue)
        value = min(max(stepped, range.lowerBound), range.upperBound)
    }

    private func steppedValue(_ raw: Double) -> Double {
        guard step > 0 else { return raw }
        let relative = (raw - range.lowerBound) / step
        let rounded = (relative).rounded()
        return range.lowerBound + rounded * step
    }
}

private struct FlatSliderPreview: View {
    @State private var value = 0.95

    var body: some View {
        FlatSlider(value: $value, range: 0.8...1.1, step: 0.001)
            .padding()
            .frame(width: 280)
    }
}

#Preview {
    FlatSliderPreview()
}
