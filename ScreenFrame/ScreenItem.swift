//
//  ScreenItem.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import AppKit
import Foundation

enum ScreenshotOrientation: Hashable {
    case portrait
    case landscape

    init(imageSize: CGSize) {
        if imageSize.width > imageSize.height {
            self = .landscape
        } else {
            self = .portrait
        }
    }

    var isLandscape: Bool { self == .landscape }
}

struct ScreenItem: Identifiable {
    let id = UUID()
    let url: URL
    let image: NSImage
    var device: DeviceProfile
    var color: DeviceColor
    var contentScaleOverride: Double?
    var orientation: ScreenshotOrientation

    var displayName: String { url.lastPathComponent }

    var sanitizedName: String {
        let base = url.deletingPathExtension().lastPathComponent
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = base.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let joined = String(filtered).replacingOccurrences(of: "--", with: "-")
        return joined.isEmpty ? "screenshot" : joined
    }

    init(
        url: URL,
        image: NSImage,
        device: DeviceProfile,
        color: DeviceColor,
        orientation: ScreenshotOrientation? = nil,
        contentScaleOverride: Double? = nil
    ) {
        self.url = url
        self.image = image
        self.device = device
        self.color = color
        self.orientation = orientation ?? ScreenshotOrientation(imageSize: image.size)
        self.contentScaleOverride = contentScaleOverride
    }
}

extension NSImage {
    func applying(orientation: ScreenshotOrientation) -> NSImage? {
        switch orientation {
        case .portrait:
            return self
        case .landscape:
            return rotated90DegreesCounterClockwise()
        }
    }

    private func rotated90DegreesCounterClockwise() -> NSImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        guard let cgImage = cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }
        let newSize = CGSize(width: size.height, height: size.width)
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return nil
        }
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: .pi / 2)
        context.translateBy(x: -size.width / 2, y: -size.height / 2)
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let rotatedCGImage = context.makeImage() else { return nil }
        return NSImage(cgImage: rotatedCGImage, size: newSize)
    }
}
