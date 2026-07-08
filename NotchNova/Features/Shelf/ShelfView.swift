import SwiftUI

/// Drop zone + stashed files. Items drag out to Finder, Mail, anywhere.
struct ShelfView: View {
    @EnvironmentObject var shelf: ShelfStore
    @EnvironmentObject var vm: NotchViewModel

    var body: some View {
        VStack(spacing: 8) {
            if shelf.items.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelf.items) { item in
                            ShelfItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }

                HStack {
                    Text("\(shelf.items.count) item\(shelf.items.count == 1 ? "" : "s") — drag out to use")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button("Clear all") { shelf.clear() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.horizontal, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: vm.dragTargeted ? "tray.and.arrow.down.fill" : "tray.fill")
                .font(.system(size: 30))
                .foregroundStyle(vm.dragTargeted ? Theme.accent : Theme.textSecondary)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(vm.dragTargeted ? 1.15 : 1)
                .animation(vm.spring, value: vm.dragTargeted)
            Text(vm.dragTargeted ? "Drop it!" : "Drag files onto the notch to stash them")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    vm.dragTargeted ? Theme.accent : Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                )
                .padding(.horizontal, 10)
        )
    }
}

struct ShelfItemView: View {
    @EnvironmentObject var shelf: ShelfStore
    let item: ShelfItem
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let thumb = shelf.thumbnails[item.id] {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(width: 58, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(hovering ? Theme.surfaceHover : Theme.surface)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                if hovering {
                    Button {
                        shelf.remove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white, .black.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 5, y: -5)
                }
            }

            Text(item.name)
                .font(.system(size: 9.5))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 62)
        }
        .onHover { hovering = $0 }
        .onDrag { NSItemProvider(object: item.url as NSURL) }
        .onTapGesture(count: 2) { shelf.openInFinder(item) }
        .help("Drag out to use • double-click to reveal in Finder")
    }
}
