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
import AlertToast

struct ContentView: View {
    @State private var items: [ScreenItem] = []
    @State private var selectedItemID: ScreenItem.ID?
    @State private var isTargeted = false
    @State private var exportMessage: String?
    @State private var exportError: String?
    @State private var isExporting = false
    @State private var copyError: String?
    @State private var isCopying = false
    @State private var showCopyToast = false
    @FocusState private var listFocused: Bool
    @State private var inspectorPresented = true
    
    private var selectedItem: ScreenItem? {
        guard let id = selectedItemID else { return nil }
        return items.first { $0.id == id }
    }

    private var selectedItemBinding: Binding<ScreenItem?> {
        Binding(
            get: { selectedItem },
            set: { updatedItem in
                guard let updatedItem else { return }
                if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
                    items[index] = updatedItem
                }
            }
        )
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                DropHint(isTargeted: isTargeted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .contentShape(Rectangle())
                    .padding(.bottom, 12)
                
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
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.top, 8)
                .frame(minWidth: 320)
                .frame(maxHeight: .infinity)
                .focused($listFocused)
                if !items.isEmpty {
                    Button(action: downloadAll) {
                        Label("Export all", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 12)
                }
            }
            .onMoveCommand(perform: handleMoveCommand(_:))
            .toolbar {
                ToolbarItem {
                    Button(action: downloadAll) {
                        Label("Export all", systemImage: "square.and.arrow.down")
                    }
                    .disabled(items.isEmpty || isExporting)
                }
            }
            .padding()
            .background(Color.clear)
        } detail: {
            PreviewPanel(item: selectedItemBinding)
                .padding()
                .toolbar {
                    ToolbarItem {
                        Button {
                            inspectorPresented.toggle()
                        } label: {
                            Label("Inspector", systemImage: "sidebar.trailing")
                        }
                        .labelStyle(.iconOnly)
                        .help("Toggle inspector")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: copySelectedItem) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(selectedItem == nil || isCopying)
                    }
                }
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
        .alert("Copy failed", isPresented: Binding(get: { copyError != nil }, set: { if !$0 { copyError = nil } })) {
            Button("OK", role: .cancel) {
                copyError = nil
            }
        } message: {
            Text(copyError ?? "")
        }
        .toast(isPresenting: $showCopyToast) {
            AlertToast(type: .systemImage("doc.on.doc", Color.white), title: "Copied to clipboard")
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop(providers:))
        .inspector(isPresented: $inspectorPresented) {
            InspectorPanel(item: selectedItemBinding)
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

    private func copySelectedItem() {
        guard !isCopying, let item = selectedItem else { return }
        isCopying = true
        Task {
            defer { isCopying = false }
            do {
                let data = try FrameRenderer.pngData(for: item)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setData(data, forType: .png)
                showCopyToast = true
            } catch {
                copyError = error.localizedDescription
            }
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
    
#Preview {
    ContentView()
}
