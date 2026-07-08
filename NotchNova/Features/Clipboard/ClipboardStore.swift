import AppKit

struct ClipEntry: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let date: Date

    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 120 ? String(trimmed.prefix(120)) + "…" : trimmed
    }
}

/// Text clipboard history via changeCount polling (the only public way).
@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var entries: [ClipEntry] = []

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var suppressNext = false
    private let maxEntries = 30

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard Prefs.bool(.clipboardEnabled, default: true) else { return }
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if suppressNext {
            suppressNext = false
            return
        }
        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        entries.removeAll { $0.text == text }
        entries.insert(ClipEntry(text: text, date: Date()), at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    func copy(_ entry: ClipEntry) {
        suppressNext = true
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(entry.text, forType: .string)
        lastChangeCount = pb.changeCount
    }

    func remove(_ entry: ClipEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func clear() {
        entries.removeAll()
    }
}
