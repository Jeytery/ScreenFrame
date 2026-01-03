//
//  ScreenRow.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI

struct ScreenRow: View {
    @Binding var item: ScreenItem
    let isSelected: Bool
    let onDelete: () -> Void

    @ViewBuilder
    private func pickerChrome<V: View>(_ view: V) -> some View {
        view
            .controlSize(.small)
            .background(.quaternary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(.secondary.opacity(0.25), lineWidth: 1)
            )
//        if isSelected {
//            view
//                .controlSize(.small)
//                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 6, style: .continuous)
//                        .stroke(.white.opacity(0.25), lineWidth: 1)
//                )
//                .environment(\.colorScheme, .dark)
//        } else {
//            view
//                .controlSize(.small)
//                .background(.quaternary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 6, style: .continuous)
//                        .stroke(.secondary.opacity(0.25), lineWidth: 1)
//                )
//        }
    }

    private var deleteButtonBackground: some ShapeStyle {
        isSelected ? AnyShapeStyle(.white.opacity(0.18)) : AnyShapeStyle(.secondary.opacity(0.10))
    }

    private var deleteButtonForeground: some ShapeStyle {
        isSelected ? AnyShapeStyle(.white.opacity(0.95)) : AnyShapeStyle(.red)
    }

    private var deleteButtonStroke: some ShapeStyle {
        isSelected ? AnyShapeStyle(.white.opacity(0.22)) : AnyShapeStyle(.secondary.opacity(0.20))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    pickerChrome(
                        Picker("Device", selection: $item.device) {
                            ForEach(DeviceLibrary.catalog) { profile in
                                Text(profile.name).tag(profile)
                            }
                        }
                        .labelsHidden()
                    )

                    pickerChrome(
                        Picker("Color", selection: $item.color) {
                            ForEach(item.device.colors) { color in
                                Text(color.name).tag(color)
                            }
                        }
                        .labelsHidden()
                    )
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(deleteButtonBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(deleteButtonStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Delete this screenshot")
            .foregroundStyle(deleteButtonForeground)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .padding(8)
        .onChange(of: item.device) { newDevice in
            if !newDevice.colors.contains(item.color), let firstColor = newDevice.colors.first {
                item.color = firstColor
            }
        }
    }
}
