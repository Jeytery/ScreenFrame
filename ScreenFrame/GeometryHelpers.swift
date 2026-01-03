//
//  GeometryHelpers.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import CoreGraphics

func aspectFitRect(for contentSize: CGSize, in container: CGRect) -> CGRect {
    let contentAspect = contentSize.width / contentSize.height
    let containerAspect = container.width / container.height
    var rect = container

    if contentAspect > containerAspect {
        let height = container.width / contentAspect
        rect.origin.y += (container.height - height) / 2
        rect.size = CGSize(width: container.width, height: height)
    } else {
        let width = container.height * contentAspect
        rect.origin.x += (container.width - width) / 2
        rect.size = CGSize(width: width, height: container.height)
    }
    return rect
}

func scaleRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
    guard scale != 1 else { return rect }
    let newWidth = rect.width * scale
    let newHeight = rect.height * scale
    let dx = (rect.width - newWidth) / 2
    let dy = (rect.height - newHeight) / 2
    return rect.insetBy(dx: dx, dy: dy)
}

func rectFromTopToBottom(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
    CGRect(x: rect.minX, y: containerHeight - rect.maxY, width: rect.width, height: rect.height)
}

func rectFromBottomToTop(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
    CGRect(x: rect.minX, y: containerHeight - rect.maxY, width: rect.width, height: rect.height)
}
