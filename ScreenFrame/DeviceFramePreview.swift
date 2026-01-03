//
//  DeviceFramePreview.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI
import AppKit

struct DeviceFramePreview: View {
    let image: NSImage
    let device: DeviceProfile
    let color: DeviceColor
    let contentScale: CGFloat
    let orientation: ScreenshotOrientation

    var body: some View {
        GeometryReader { proxy in
            frame(in: proxy.size)
        }
    }

    @ViewBuilder
    private func frame(in availableSize: CGSize) -> some View {
        if let style = device.frameStyle {
            if let frameImage = NSImage(named: NSImage.Name(color.frameAssetName)) {
                frameWithAsset(in: availableSize, style: style, frameImage: frameImage)
            } else {
                missingAssetView(message: "Asset \(color.frameAssetName) not found.")
            }
        } else {
            missingAssetView(message: "No frame style for \(device.name).")
        }
    }

    @ViewBuilder
    private func frameWithAsset(in availableSize: CGSize, style: FrameStyle, frameImage: NSImage) -> some View {
        if let orientedFrame = frameImage.applying(orientation: orientation) {
            let aspect = orientedFrame.size.width / orientedFrame.size.height
            let containerAspect = availableSize.width / availableSize.height
            let previewWidth: CGFloat = {
                if containerAspect > aspect {
                    return availableSize.height * aspect
                } else {
                    return availableSize.width
                }
            }()
            let previewHeight = previewWidth / aspect
            let orientedInsets = style.insets.oriented(for: orientation)
            let screenRectTop = orientedInsets.rectInTopCoordinate(in: CGSize(width: previewWidth, height: previewHeight))
            let fittedTopRect = fittedRectForPreview(screenRectTop, previewHeight: previewHeight)
            let scaledTopRect = scaleRect(fittedTopRect, scale: contentScale)
            let cornerRadius = min(scaledTopRect.width, scaledTopRect.height) * style.screenCornerRadiusRatio

            ZStack(alignment: .topLeading) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: scaledTopRect.width, height: scaledTopRect.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .offset(x: scaledTopRect.minX, y: scaledTopRect.minY)
                Image(nsImage: orientedFrame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: previewWidth, height: previewHeight)
            }
            .frame(width: previewWidth, height: previewHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            missingAssetView(message: "Unable to rotate asset \(color.frameAssetName).")
        }
    }

    private func fittedRectForPreview(_ rect: CGRect, previewHeight: CGFloat) -> CGRect {
        let containerBottomRect = rectFromTopToBottom(rect, containerHeight: previewHeight)
        let fittedBottom = aspectFitRect(for: image.size, in: containerBottomRect)
        return rectFromBottomToTop(fittedBottom, containerHeight: previewHeight)
    }

    private func missingAssetView(message: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [5]))
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
