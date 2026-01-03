//
//  PreviewPanel.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI

struct PreviewPanel: View {
    let item: ScreenItem?

    var body: some View {
        VStack {
            if let item {
                Text(item.device.name)
                    .font(.title)
                Text(item.color.name)
                    .foregroundStyle(.secondary)

                DeviceFramePreview(image: item.image, device: item.device, color: item.color)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Select a screenshot to preview")
                        .font(.headline)
                    Text("Use the list on the left or arrow keys.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}
