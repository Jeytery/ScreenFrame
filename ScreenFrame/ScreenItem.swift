//
//  ScreenItem.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import AppKit
import Foundation

struct ScreenItem: Identifiable {
    let id = UUID()
    let url: URL
    let image: NSImage
    var device: DeviceProfile
    var color: DeviceColor

    var displayName: String { url.lastPathComponent }

    var sanitizedName: String {
        let base = url.deletingPathExtension().lastPathComponent
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = base.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let joined = String(filtered).replacingOccurrences(of: "--", with: "-")
        return joined.isEmpty ? "screenshot" : joined
    }
}
