import AppKit
import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing

struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    var name: String { url.lastPathComponent }
}

@MainActor
final class ShelfStore: ObservableObject {
    @Published private(set) var items: [ShelfItem] = []
    @Published private(set) var thumbnails: [UUID: NSImage] = [:]

    var onItemAdded: (@MainActor (String) -> Void)?

    private var storageURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchNova", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("shelf.json")
    }

    init() {
        load()
    }

    func add(from providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let u = item as? URL {
                    url = u
                }
                guard let url else { return }
                Task { @MainActor in
                    self.add(url: url)
                }
            }
        }
    }

    func add(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard !items.contains(where: { $0.url == url }) else { return }
        let item = ShelfItem(id: UUID(), url: url)
        withAnimation { items.insert(item, at: 0) }
        generateThumbnail(for: item)
        save()
        onItemAdded?(item.name)
    }

    func remove(_ item: ShelfItem) {
        withAnimation { items.removeAll { $0.id == item.id } }
        thumbnails[item.id] = nil
        save()
    }

    func clear() {
        withAnimation { items.removeAll() }
        thumbnails.removeAll()
        save()
    }

    func openInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    // MARK: - Thumbnails

    private func generateThumbnail(for item: ShelfItem) {
        // Instant fallback: the Finder icon.
        thumbnails[item.id] = NSWorkspace.shared.icon(forFile: item.url.path)

        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: CGSize(width: 96, height: 96),
            scale: 2,
            representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
            guard let rep else { return }
            let image = rep.nsImage
            Task { @MainActor in
                self.thumbnails[item.id] = image
            }
        }
    }

    // MARK: - Persistence

    func save() {
        let paths = items.map { $0.url.path }
        if let data = try? JSONEncoder().encode(paths) {
            try? data.write(to: storageURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let paths = try? JSONDecoder().decode([String].self, from: data) else { return }
        items = paths
            .filter { FileManager.default.fileExists(atPath: $0) }
            .map { ShelfItem(id: UUID(), url: URL(fileURLWithPath: $0)) }
        for item in items {
            generateThumbnail(for: item)
        }
    }
}
