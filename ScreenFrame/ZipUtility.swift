//
//  ZipUtility.swift
//  ScreenFrame
//
//  Created by Dmytro Ostapchenko on 27.12.2025.
//

import Foundation

enum ZipUtility {
    static func archive(folder: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
            throw NSError(domain: "ZipUtility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Source folder does not exist"])
        }

        let tempZip = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
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

        try FileManager.default.moveItem(at: tempZip, to: destination)
    }
}
