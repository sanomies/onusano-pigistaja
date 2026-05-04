import AppKit
import UniformTypeIdentifiers  // UTType.fileURL used in drag-and-drop

final class ViewModel: ObservableObject {
    @Published var files: [URL] = []
    @Published var isProcessing = false
    @Published var statusMessage = ""
    @Published var showConfetti = false

    // MARK: - File ingestion

    func addDroppedItems(_ providers: [NSItemProvider]) {
        Task { @MainActor in
            var newURLs: [URL] = []
            for provider in providers {
                guard let url = await Self.loadURL(from: provider) else { continue }
                newURLs += Self.expandToImages(url)
            }
            merge(newURLs)
        }
    }

    func openPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.message = "Vali pildifailid või kaustad"
        guard panel.runModal() == .OK else { return }
        merge(panel.urls.flatMap(Self.expandToImages))
    }

    private func merge(_ urls: [URL]) {
        let existing = Set(files.map(\.path))
        files += urls.filter { !existing.contains($0.path) }
    }

    // MARK: - Processing

    func processFiles() {
        guard !files.isEmpty else { return }
        let toProcess = files
        isProcessing = true
        statusMessage = "Pigistan pilte..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var entries: [(String, Data)] = []
            for file in toProcess {
                if let data = Self.processFile(file) {
                    entries.append((file.lastPathComponent, data))
                }
            }

            let folderName = Self.outputFolderName(for: toProcess)
            let downloads  = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let outputDir  = Self.uniqueFolder(base: downloads.appendingPathComponent(folderName))

            do {
                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
                for (name, data) in entries {
                    try data.write(to: outputDir.appendingPathComponent(name))
                }
                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([outputDir])
                    self?.showConfetti = true
                    self?.files        = []
                    self?.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async { self?.isProcessing = false }
                print("Output error: \(error)")
            }
        }
    }

    // Derive folder name from the common base of input filenames.
    // "hellohello_600x250px.jpg" → "hellohello-squeezed"
    private static func outputFolderName(for urls: [URL]) -> String {
        let regex = try? NSRegularExpression(pattern: #"^(.+?)_\d+x\d+px\."#)
        let bases: [String] = urls.compactMap { url in
            let name = url.lastPathComponent
            guard let m = regex?.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
                  let r = Range(m.range(at: 1), in: name) else { return nil }
            return String(name[r])
        }
        let unique = Set(bases)
        if unique.count == 1, let base = unique.first { return "\(base)-squeezed" }
        if bases.count > 1 {
            let prefix = bases.dropFirst().reduce(bases[0]) { a, b in
                String(zip(a, b).prefix(while: { $0.0 == $0.1 }).map(\.0))
            }.trimmingCharacters(in: CharacterSet(charactersIn: "_- "))
            if !prefix.isEmpty { return "\(prefix)-squeezed" }
        }
        return "squeezed"
    }

    private static func uniqueFolder(base: URL) -> URL {
        guard FileManager.default.fileExists(atPath: base.path) else { return base }
        var i = 2
        while true {
            let candidate = base.deletingLastPathComponent()
                .appendingPathComponent("\(base.lastPathComponent)-\(i)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            i += 1
        }
    }

    // MARK: - Static helpers

    private static func processFile(_ url: URL) -> Data? {
        if url.pathExtension.lowercased() == "png" {
            return try? Data(contentsOf: url)
        }
        return ImageProcessor.compressJPEG(at: url, toMaxKB: targetKB(for: url.lastPathComponent))
    }

    private static func targetKB(for name: String) -> Int {
        if name.contains("800x50px")   { return 19  }
        if name.contains("600x250px")  { return 105 }
        if name.contains("600x100px")  { return 43  }
        if name.contains("1600x300px") { return 105 }
        if name.contains("1600x100px") { return 43  }
        return 98
    }

    static func expandToImages(_ url: URL) -> [URL] {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue {
            return (FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )?.allObjects as? [URL] ?? []).filter(isImage)
        }
        return isImage(url) ? [url] : []
    }

    private static func isImage(_ url: URL) -> Bool {
        ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic"]
            .contains(url.pathExtension.lowercased())
    }

    private static func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                switch item {
                case let url  as URL:  continuation.resume(returning: url)
                case let data as Data: continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                default:               continuation.resume(returning: nil)
                }
            }
        }
    }
}
