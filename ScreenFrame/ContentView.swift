//
//  ContentView.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import SwiftUI
import UniformTypeIdentifiers
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
        )
    ]

    static var fallback: DeviceProfile { catalog.first! }

    static func matchingDevice(for imageSize: CGSize) -> DeviceProfile {
        let sortedImage = [imageSize.width, imageSize.height].sorted()
        for profile in catalog {
            let sortedDevice = [profile.displaySize.width, profile.displaySize.height].sorted()
            if abs(sortedImage[0] - sortedDevice[0]) < 15 && abs(sortedImage[1] - sortedDevice[1]) < 15 {
                return profile
            }
        }
        return catalog.first { $0.family == .macBook } ?? fallback
    }
}

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

enum ZipUtility {
    static func archive(folder: URL, to destination: URL) throws {
        // Remove any existing destination file
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        // Ensure folder exists
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
            throw NSError(domain: "ZipUtility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Source folder does not exist"])
        }

        // Use /usr/bin/zip -r --symlinks -y to zip the folder contents without keeping the parent directory,
        // mirroring shouldKeepParentDirectory: false by zipping the folder's contents.
        // We do this by running zip from within the folder and zipping "." then moving the result.
        let tempZip = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")

        // We want to zip the contents of the folder, not the folder itself.
        // Run zip from the folder directory and zip everything inside: zip -r <tempZip> .
        process.currentDirectoryURL = folder
        process.arguments = ["-r", "-y", tempZip.path, "."]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ZipUtility", code: 3, userInfo: [NSLocalizedDescriptionKey: "zip failed: \(output)"])
        }

        // Move temp zip to destination
        try FileManager.default.moveItem(at: tempZip, to: destination)
    }
}

struct ContentView: View {
    @State private var items: [ScreenItem] = []
    @State private var selectedItemID: ScreenItem.ID?
    @State private var isTargeted = false
    @State private var exportMessage: String?
    @State private var exportError: String?
    @State private var isExporting = false
    @FocusState private var listFocused: Bool

    private var selectedItem: ScreenItem? {
        guard let id = selectedItemID else { return nil }
        return items.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                DropHint(isTargeted: isTargeted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .contentShape(Rectangle())
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop(providers:))

                if !items.isEmpty {
                    Divider()
                }

                List(selection: $selectedItemID) {
                    ForEach($items) { $item in
                        ScreenRow(
                            item: $item,
                            isSelected: selectedItemID == item.id,
                            onDelete: { deleteItem(id: item.id) }
                        )
                        .tag(item.id)
                    }
                    .onDelete(perform: deleteItems(at:))
                }
                .listStyle(.inset)
                .frame(minWidth: 320)
                .frame(maxHeight: .infinity)
                .focused($listFocused)

                if !items.isEmpty {
                    Button(action: downloadAll) {
                        Label("Download all", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 12)
                }
            }
            .onMoveCommand(perform: handleMoveCommand(_:))
            .toolbar {
                ToolbarItem {
                    Button(action: downloadAll) {
                        Label("Download all", systemImage: "square.and.arrow.down")
                    }
                    .disabled(items.isEmpty || isExporting)
                }
            }
            .padding()
        } detail: {
            PreviewPanel(item: selectedItem)
        }
        .alert("Export complete", isPresented: Binding(get: { exportMessage != nil }, set: { if !$0 { exportMessage = nil } })) {
            Button("OK", role: .cancel) {
                exportMessage = nil
            }
        } message: {
            Text(exportMessage ?? "")
        }
        .alert("Something went wrong", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {
                exportError = nil
            }
        } message: {
            Text(exportError ?? "")
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard
                    let data = data as? Data,
                    let url = URL(dataRepresentation: data, relativeTo: nil),
                    let image = NSImage(contentsOf: url)
                else { return }

                let device = DeviceLibrary.matchingDevice(for: image.size)
                let color = device.colors.first ?? DeviceLibrary.blue
                let newItem = ScreenItem(url: url, image: image, device: device, color: color)

                DispatchQueue.main.async {
                    items.append(newItem)
                    selectedItemID = newItem.id
                }
            }
        }
        return true
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard !items.isEmpty else { return }
        guard let selectedID = selectedItemID, let index = items.firstIndex(where: { $0.id == selectedID }) else {
            selectedItemID = items.first?.id
            return
        }

        switch direction {
        case .down:
            let next = min(index + 1, items.count - 1)
            selectedItemID = items[next].id
        case .up:
            let previous = max(index - 1, 0)
            selectedItemID = items[previous].id
        default:
            break
        }
    }

    private func downloadAll() {
        guard !items.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose"
        panel.message = "Pick a folder for your framed screenshots."

        if panel.runModal() == .OK, let folder = panel.url {
            Task { await exportItems(to: folder) }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        guard !items.isEmpty else { return }
        let sortedOffsets = offsets.sorted()
        let removedIDs = sortedOffsets.compactMap { index -> ScreenItem.ID? in
            guard items.indices.contains(index) else { return nil }
            return items[index].id
        }
        let fallbackIndex = sortedOffsets.min()
        items.remove(atOffsets: offsets)
        updateSelectionAfterDeletion(removedIDs: removedIDs, fallbackIndex: fallbackIndex)
    }

    private func deleteItem(id: ScreenItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items.remove(at: index)
        updateSelectionAfterDeletion(removedIDs: [id], fallbackIndex: index)
    }

    private func updateSelectionAfterDeletion(removedIDs: [ScreenItem.ID], fallbackIndex: Int?) {
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }
        guard let selectedID = selectedItemID, removedIDs.contains(selectedID) else { return }
        if let fallbackIndex = fallbackIndex {
            let clampedIndex = max(0, min(fallbackIndex, items.count - 1))
            selectedItemID = items[clampedIndex].id
        } else {
            selectedItemID = items.first?.id
        }
    }

    @MainActor
    private func exportItems(to directory: URL) async {
        isExporting = true
        defer { isExporting = false }
        exportMessage = nil
        exportError = nil

        do {
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)

            for item in items {
                let outputURL = temp.appendingPathComponent(item.sanitizedName).appendingPathExtension("png")
                let data = try FrameRenderer.pngData(for: item)
                try data.write(to: outputURL)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let archiveName = "ScreenFrames-\(formatter.string(from: Date())).zip"
            let destination = directory.appendingPathComponent(archiveName)
            try ZipUtility.archive(folder: temp, to: destination)
            exportMessage = "Saved \(archiveName)"

            try? FileManager.default.removeItem(at: temp)
        } catch {
            exportError = error.localizedDescription
        }
    }
}

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
                Text("Drop more files anytime to keep adding.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct ScreenRow: View {
    @Binding var item: ScreenItem
    let isSelected: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(item.device.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("Delete this screenshot")
            }

            HStack {
                Picker("Device", selection: $item.device) {
                    ForEach(DeviceLibrary.catalog) { profile in
                        Text("\(profile.family.rawValue) · \(profile.name)").tag(profile)
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
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        .cornerRadius(10)
        .onChange(of: item.device) { newDevice in
            if !newDevice.colors.contains(item.color), let firstColor = newDevice.colors.first {
                item.color = firstColor
            }
        }
    }
}

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

                Text("Use Download all to export framed assets as a ZIP archive.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

struct DeviceFramePreview: View {
    let image: NSImage
    let device: DeviceProfile
    let color: DeviceColor

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

    private func frameWithAsset(in availableSize: CGSize, style: FrameStyle, frameImage: NSImage) -> some View {
        let aspect = frameImage.size.width / frameImage.size.height
        let containerAspect = availableSize.width / availableSize.height
        let previewWidth: CGFloat
        if containerAspect > aspect {
            previewWidth = availableSize.height * aspect
        } else {
            previewWidth = availableSize.width
        }
        let previewHeight = previewWidth / aspect
        let screenRectTop = style.insets.rectInTopCoordinate(in: CGSize(width: previewWidth, height: previewHeight))
        let fittedTopRect = fittedRectForPreview(screenRectTop, previewHeight: previewHeight)
        let scaledTopRect = scaleRect(fittedTopRect, scale: style.contentScale)
        let cornerRadius = min(scaledTopRect.width, scaledTopRect.height) * style.screenCornerRadiusRatio

        return ZStack(alignment: .topLeading) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: scaledTopRect.width, height: scaledTopRect.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .offset(x: scaledTopRect.minX, y: scaledTopRect.minY)
            Image(nsImage: frameImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: previewWidth, height: previewHeight)
        }
        .frame(width: previewWidth, height: previewHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private func aspectFitRect(for contentSize: CGSize, in container: CGRect) -> CGRect {
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

private func scaleRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
    guard scale != 1 else { return rect }
    let newWidth = rect.width * scale
    let newHeight = rect.height * scale
    let dx = (rect.width - newWidth) / 2
    let dy = (rect.height - newHeight) / 2
    return rect.insetBy(dx: dx, dy: dy)
}

private func rectFromTopToBottom(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
    CGRect(x: rect.minX, y: containerHeight - rect.maxY, width: rect.width, height: rect.height)
}

private func rectFromBottomToTop(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
    CGRect(x: rect.minX, y: containerHeight - rect.maxY, width: rect.width, height: rect.height)
}

#Preview {
    ContentView()
}
