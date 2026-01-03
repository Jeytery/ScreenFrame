//
//  DropHint.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI

struct DropHint: View {
    let isTargeted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isTargeted ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [10]))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.largeTitle)
                Text("Drag n drop your screenshots")
                    .font(.headline)
            }
            .padding()
        }
    }
}
