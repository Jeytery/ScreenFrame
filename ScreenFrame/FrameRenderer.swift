//
//  FrameRenderer.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import AppKit
import Foundation

enum FrameRenderer {
    static func pngData(for item: ScreenItem) throws -> Data {
        guard let style = item.device.frameStyle else {
            throw NSError(domain: "FrameRenderer", code: 2, userInfo: [NSLocalizedDescriptionKey: "No frame style for \(item.device.name)"])
        }
        guard let frameImage = NSImage(named: NSImage.Name(item.color.frameAssetName)) else {
            throw NSError(domain: "FrameRenderer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing frame asset \(item.color.frameAssetName)"])
        }
        return try renderUsingAsset(item: item, frameImage: frameImage, style: style)
    }

    private static func renderUsingAsset(item: ScreenItem, frameImage: NSImage, style: FrameStyle) throws -> Data {
        let canvasSize = frameImage.size
        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        let screenArea = style.insets.rectInBottomCoordinate(in: canvasSize)
        let fittedScreen = aspectFitRect(for: item.image.size, in: screenArea)
        let scaledScreen = scaleRect(fittedScreen, scale: style.contentScale)

        let image = NSImage(size: canvasSize)
        image.lockFocus()
        NSGraphicsContext.saveGraphicsState()
        let path = NSBezierPath(
            roundedRect: scaledScreen,
            xRadius: scaledScreen.width * style.screenCornerRadiusRatio,
            yRadius: scaledScreen.width * style.screenCornerRadiusRatio
        )
        path.addClip()
        item.image.draw(in: scaledScreen, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
        frameImage.draw(in: canvasRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        image.unlockFocus()

        guard
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let data = bitmap.representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "FrameRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to render framed asset"])
        }
        return data
    }
}
