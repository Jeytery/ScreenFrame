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
        List {
            if let item {
                Section(header: Text("Content Scale")) {
                    if let style = item.device.frameStyle, let binding = contentScaleBinding(for: style) {
                        Slider(value: binding, in: 0 ... 1)
                        valueControls(binding: binding, bounds: sliderRange(for: style))
                    } else {
                        Text("This device does not expose adjustable content scale.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Select a screenshot to edit its settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
                
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
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
                binding.wrappedValue = adjustedValue(for: binding.wrappedValue - 0.001, within: bounds)
            } label: {
                Image(systemName: "minus.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Decrease by 0.001")
            Button {
                binding.wrappedValue = adjustedValue(for: binding.wrappedValue + 0.001, within: bounds)
            } label: {
                Image(systemName: "plus.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Increase by 0.001")
        }
    }

    private func adjustedValue(for candidate: Double, within bounds: ClosedRange<Double>) -> Double {
        let clamped = min(max(candidate, bounds.lowerBound), bounds.upperBound)
        return (clamped * 1000).rounded() / 1000
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
