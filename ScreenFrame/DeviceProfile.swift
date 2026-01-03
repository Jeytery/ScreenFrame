//
//  DeviceProfile.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI

struct DeviceProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let family: DeviceFamily
    let displaySize: CGSize
    let cornerRadius: CGFloat
    let colors: [DeviceColor]
    let frameStyle: FrameStyle?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DeviceProfile, rhs: DeviceProfile) -> Bool {
        lhs.id == rhs.id
    }
}

enum DeviceFamily: String {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case macBook = "MacBook"
}

struct DeviceColor: Identifiable, Hashable {
    let id: String
    let name: String
    let frameAssetName: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DeviceColor, rhs: DeviceColor) -> Bool {
        lhs.id == rhs.id
    }
}

struct ScreenInsets: Hashable {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    func rectInTopCoordinate(in size: CGSize) -> CGRect {
        let width = size.width * (1 - leading - trailing)
        let height = size.height * (1 - top - bottom)
        let x = size.width * leading
        let y = size.height * top
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func rectInBottomCoordinate(in size: CGSize) -> CGRect {
        let width = size.width * (1 - leading - trailing)
        let height = size.height * (1 - top - bottom)
        let x = size.width * leading
        let y = size.height * bottom
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct FrameStyle: Hashable {
    let insets: ScreenInsets
    let screenCornerRadiusRatio: CGFloat
    let contentScale: CGFloat
}

enum DeviceLibrary {
    static let blue = DeviceColor(id: "blue", name: "Blue", frameAssetName: "iphone14_blue")
    static let midnight = DeviceColor(id: "midnight", name: "Midnight", frameAssetName: "iphone14_midnight")
    static let purple = DeviceColor(id: "purple", name: "Purple", frameAssetName: "iphone14_purple")
    static let red = DeviceColor(id: "red", name: "Red", frameAssetName: "iphone14_red")
    static let starlight = DeviceColor(id: "starlight", name: "Starlight", frameAssetName: "iphone14_starlight")
    static let ultramarine = DeviceColor(id: "ultramarine", name: "Ultramarine", frameAssetName: "iPhone 16 - Ultramarine - Portrait")
    static let pink16 = DeviceColor(id: "pink16", name: "Pink", frameAssetName: "iPhone 16 Plus - Pink - Portrait 2")
    static let blackTitanium = DeviceColor(id: "blackTitanium", name: "Black Titanium", frameAssetName: "iPhone 16 Pro - Black Titanium - Portrait 2")
    static let desertTitanium = DeviceColor(id: "desertTitanium", name: "Desert Titanium", frameAssetName: "iPhone 16 Pro Max - Desert Titanium - Portrait 2")
    static let mistBlue = DeviceColor(id: "mistBlue", name: "Mist Blue", frameAssetName: "iPhone 17 - Mist Blue - Portrait 1")
    static let cosmicOrange = DeviceColor(id: "cosmicOrange", name: "Cosmic Orange", frameAssetName: "iPhone 17 Pro - Cosmic Orange - Portrait 1")
    static let cosmicOrangeMax = DeviceColor(id: "cosmicOrangeMax", name: "Cosmic Orange", frameAssetName: "iPhone 17 Pro Max - Cosmic Orange - Portrait 1")
    static let spaceGray = DeviceColor(id: "spaceGray", name: "Space Gray", frameAssetName: "iPad Pro 12.9 - Space Gray - Portrait")

    static let catalog: [DeviceProfile] = [
        DeviceProfile(
            id: "iphone14",
            name: "iPhone 14",
            family: .iPhone,
            displaySize: CGSize(width: 2532, height: 1170),
            cornerRadius: 106,
            colors: [blue, midnight, purple, red, starlight],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 6.0 / 850.0,
                    leading: 10.0 / 421.0,
                    bottom: 8.0 / 850.0,
                    trailing: 11.0 / 421.0
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone16",
            name: "iPhone 16",
            family: .iPhone,
            displaySize: CGSize(width: 2556, height: 1179),
            cornerRadius: 108,
            colors: [ultramarine],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 1.0 / 879.0,
                    leading: 0,
                    bottom: 1.0 / 879.0,
                    trailing: 0
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone16Plus",
            name: "iPhone 16 Plus",
            family: .iPhone,
            displaySize: CGSize(width: 2796, height: 1290),
            cornerRadius: 112,
            colors: [pink16],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 2.0 / 964.0,
                    leading: 0,
                    bottom: 2.0 / 964.0,
                    trailing: 0
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone16Pro",
            name: "iPhone 16 Pro",
            family: .iPhone,
            displaySize: CGSize(width: 2556, height: 1179),
            cornerRadius: 110,
            colors: [blackTitanium],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 3.0 / 884.0,
                    leading: 0,
                    bottom: 1.0 / 884.0,
                    trailing: 0
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone16ProMax",
            name: "iPhone 16 Pro Max",
            family: .iPhone,
            displaySize: CGSize(width: 2796, height: 1290),
            cornerRadius: 118,
            colors: [desertTitanium],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 1.0 / 958.0,
                    leading: 0,
                    bottom: 1.0 / 958.0,
                    trailing: 0
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone17",
            name: "iPhone 17",
            family: .iPhone,
            displaySize: CGSize(width: 2556, height: 1179),
            cornerRadius: 110,
            colors: [mistBlue],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 0.009101,
                    leading: 0.011628,
                    bottom: 0.009101,
                    trailing: 0.011628
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone17Pro",
            name: "iPhone 17 Pro",
            family: .iPhone,
            displaySize: CGSize(width: 2556, height: 1179),
            cornerRadius: 112,
            colors: [cosmicOrange],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 0.006826,
                    leading: 0.009302,
                    bottom: 0.006826,
                    trailing: 0.009302
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "iphone17ProMax",
            name: "iPhone 17 Pro Max",
            family: .iPhone,
            displaySize: CGSize(width: 2796, height: 1290),
            cornerRadius: 120,
            colors: [cosmicOrangeMax],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 0.006263,
                    leading: 0.010661,
                    bottom: 0.006263,
                    trailing: 0.010661
                ),
                screenCornerRadiusRatio: 0.06,
                contentScale: 0.97
            )
        ),
        DeviceProfile(
            id: "ipadPro129",
            name: "iPad Pro 12.9",
            family: .iPad,
            displaySize: CGSize(width: 2752, height: 2064),
            cornerRadius: 0,
            colors: [spaceGray],
            frameStyle: FrameStyle(
                insets: ScreenInsets(
                    top: 0,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                ),
                screenCornerRadiusRatio: 0,
                contentScale: 0.94
            )
        )
    ]

    static var fallback: DeviceProfile { catalog.first! }

    static func matchingDevice(for imageSize: CGSize) -> DeviceProfile {
        guard let first = catalog.first else { return fallback }
        let sortedImage = [imageSize.width, imageSize.height].sorted()
        var bestDevice = first
        var bestScore = CGFloat.greatestFiniteMagnitude

        for profile in catalog {
            let sortedDevice = [profile.displaySize.width, profile.displaySize.height].sorted()
            let widthDiff = abs(sortedImage[0] - sortedDevice[0]) / sortedDevice[0]
            let heightDiff = abs(sortedImage[1] - sortedDevice[1]) / sortedDevice[1]
            let score = widthDiff + heightDiff
            if score < bestScore {
                bestScore = score
                bestDevice = profile
            }
        }
        return bestDevice
    }
}
