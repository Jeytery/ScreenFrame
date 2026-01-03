//
//  InspectorPanel.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI
import AppKit
import Foundation

struct InspectorPanel: View {
    @Binding var item: ScreenItem?

    private let scaleFormat = FloatingPointFormatStyle<Double>
        .number
        .precision(.fractionLength(3))
        .locale(Locale(identifier: "en_US_POSIX"))

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let item {
                if let style = item.device.frameStyle, let binding = contentScaleBinding(for: style) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content Scale")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: binding, in: sliderRange(for: style), step: 0.001)
                        valueControls(binding: binding, bounds: sliderRange(for: style))
                    }
                } else {
                    Text("This device does not expose adjustable content scale.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Select a screenshot to edit its settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 240, maxWidth: 320, maxHeight: .infinity)
    }

    private func contentScaleBinding(for style: FrameStyle) -> Binding<Double>? {
        Binding<Double>(
            get: {
                let fallback = Double(style.contentScale)
                return item?.contentScaleOverride ?? fallback
            },
            set: { newValue in
                guard var currentItem = item else { return }
                let fallback = Double(style.contentScale)
                if abs(newValue - fallback) < 0.0005 {
                    currentItem.contentScaleOverride = nil
                } else {
                    currentItem.contentScaleOverride = newValue
                }
                item = currentItem
            }
        )
    }

    private func sliderRange(for style: FrameStyle) -> ClosedRange<Double> {
        let base = Double(style.contentScale)
        let lower = max(0.5, base - 0.2)
        let upper = min(1.3, base + 0.2)
        return lower...upper
    }

    @ViewBuilder
    private func valueControls(binding: Binding<Double>, bounds: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            TextField("Value", value: binding, format: scaleFormat)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(width: 70)

            Button {
                binding.wrappedValue = adjustedValue(for: binding.wrappedValue - 0.01, within: bounds)
            } label: {
                Image(systemName: "minus.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Decrease by 0.01")

            Button {
                binding.wrappedValue = adjustedValue(for: binding.wrappedValue + 0.01, within: bounds)
            } label: {
                Image(systemName: "plus.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Increase by 0.01")
        }
    }

    private func adjustedValue(for candidate: Double, within bounds: ClosedRange<Double>) -> Double {
        let clamped = min(max(candidate, bounds.lowerBound), bounds.upperBound)
        return (clamped * 100).rounded() / 100
    }
}

#Preview {
    InspectorPanel(
        item: .constant(
            ScreenItem(
                url: URL(fileURLWithPath: "/tmp/mock.png"),
                image: NSImage(size: CGSize(width: 1284, height: 2778)),
                device: DeviceLibrary.catalog.first!,
                color: DeviceLibrary.catalog.first!.colors.first ?? DeviceLibrary.blue,
                contentScaleOverride: nil
            )
        )
    )
    .frame(width: 280)
}
