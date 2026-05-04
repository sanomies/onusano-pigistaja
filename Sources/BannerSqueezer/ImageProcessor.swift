import AppKit

enum ImageProcessor {

    // Binary-search for highest JPEG quality that fits within maxKB — mirrors the JS compressToSize()
    static func compressJPEG(at url: URL, toMaxKB maxKB: Int) -> Data? {
        guard let image  = NSImage(contentsOf: url),
              let tiff   = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }

        var low  = 0.1
        var high = 1.0
        var best = bitmap.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: low)])

        while high - low > 0.01 {
            let mid = (low + high) / 2
            guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: mid)]) else { break }
            if data.count > maxKB * 1024 {
                high = mid
            } else {
                low = mid
                best = data
            }
        }
        return best
    }

    // Writes files into a temp `squeezed/` folder then zips it with the system `/usr/bin/zip`
    static func makeZip(entries: [(name: String, data: Data)]) throws -> URL {
        let tmp       = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let squeezed  = tmp.appendingPathComponent("squeezed")
        try FileManager.default.createDirectory(at: squeezed, withIntermediateDirectories: true)

        for (name, data) in entries {
            try data.write(to: squeezed.appendingPathComponent(name))
        }

        let zipURL = tmp.appendingPathComponent("squeezed.zip")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        proc.arguments    = ["-r", zipURL.path, "squeezed"]
        proc.currentDirectoryURL = tmp
        try proc.run()
        proc.waitUntilExit()

        guard proc.terminationStatus == 0 else { throw CocoaError(.fileWriteUnknown) }
        return zipURL
    }
}
