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

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Picker("Device", selection: $item.device) {
                        ForEach(DeviceLibrary.catalog) { profile in
                            Text(profile.name).tag(profile)
                        }
                    }
                    .labelsHidden()

                    Picker("Color", selection: $item.color) {
                        ForEach(item.device.colors) { color in
                            Text(color.name).tag(color)
                        }
                    }
                    .labelsHidden()
                }
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help("Delete this screenshot")
            .foregroundStyle(.red)
        }
        .padding(8)
        .onChange(of: item.device) { newDevice in
            if !newDevice.colors.contains(item.color), let firstColor = newDevice.colors.first {
                item.color = firstColor
            }
        }
    }
}
