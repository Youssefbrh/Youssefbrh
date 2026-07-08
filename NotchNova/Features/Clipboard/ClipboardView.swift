import SwiftUI

struct ClipboardView: View {
    @EnvironmentObject var clipboard: ClipboardStore
    @State private var copiedID: UUID?

    var body: some View {
        if clipboard.entries.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.textSecondary)
                Text("Copy something — it shows up here")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(clipboard.entries) { entry in
                        ClipRow(
                            entry: entry,
                            copied: copiedID == entry.id,
                            onCopy: {
                                clipboard.copy(entry)
                                copiedID = entry.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    if copiedID == entry.id { copiedID = nil }
                                }
                            },
                            onDelete: { clipboard.remove(entry) }
                        )
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
}

private struct ClipRow: View {
    let entry: ClipEntry
    let copied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.preview)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if copied {
                Label("Copied", systemImage: "checkmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.green)
                    .labelStyle(.titleAndIcon)
            } else if hovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(hovering ? Theme.surfaceHover : Theme.surface)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onCopy)
        .onHover { hovering = $0 }
    }
}
