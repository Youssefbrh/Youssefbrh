import SwiftUI
import UniformTypeIdentifiers

/// Root view living inside the transparent panel. Hosts the morphing island
/// plus the glow and the peeking pet around it.
struct NotchContainerView: View {
    @EnvironmentObject var vm: NotchViewModel
    @EnvironmentObject var shelf: ShelfStore
    @EnvironmentObject var media: MediaController
    @EnvironmentObject var alerts: AlertCenter
    @EnvironmentObject var pet: PetEngine

    @AppStorage(Prefs.Key.petEnabled.rawValue) private var petEnabled = true
    @AppStorage(Prefs.Key.petPeeks.rawValue) private var petPeeks = true

    private let topRadius: CGFloat = 8

    private var isExpanded: Bool { vm.state == .expanded }

    private var wingExtra: CGFloat {
        guard !isExpanded else { return 0 }
        return (vm.hudEvent != nil || alerts.current != nil) ? 230 : 0
    }

    private var islandWidth: CGFloat {
        isExpanded
            ? vm.expandedSize.width
            : vm.geometry.notchWidth + topRadius * 2 + wingExtra
    }

    private var islandHeight: CGFloat {
        isExpanded ? vm.expandedSize.height : vm.geometry.notchHeight
    }

    var body: some View {
        ZStack(alignment: .top) {
            AuroraGlowView(isExpanded: isExpanded)
                .frame(width: islandWidth + 60, height: islandHeight + 40)
                .allowsHitTesting(false)

            island

            if petEnabled, petPeeks, !isExpanded {
                PetView(size: 26, interactive: true)
                    .offset(x: pet.peekOffsetX, y: vm.geometry.notchHeight - 7)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var island: some View {
        ZStack(alignment: .top) {
            NotchShape(topRadius: topRadius, bottomRadius: isExpanded ? Theme.cornerRadius : 11)
                .fill(Theme.islandBackground)
                .shadow(color: .black.opacity(isExpanded ? 0.6 : 0), radius: 16, y: 6)

            if isExpanded {
                ExpandedView()
                    .padding(.horizontal, topRadius + 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                ClosedNotchView()
                    .padding(.horizontal, topRadius)
            }
        }
        .frame(width: islandWidth, height: islandHeight)
        .contentShape(NotchShape(topRadius: topRadius, bottomRadius: isExpanded ? Theme.cornerRadius : 11))
        .onHover { vm.hoverChanged($0) }
        .onTapGesture {
            if !isExpanded { vm.open() }
        }
        .onDrop(of: [UTType.fileURL], delegate: NotchDropDelegate(vm: vm, shelf: shelf))
        .animation(vm.spring, value: isExpanded)
        .animation(vm.spring, value: wingExtra)
    }
}

/// Dragging files toward the notch springs it open on the Shelf; dropping
/// anywhere on the island stashes them.
struct NotchDropDelegate: DropDelegate {
    let vm: NotchViewModel
    let shelf: ShelfStore

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.fileURL])
    }

    func dropEntered(info: DropInfo) {
        Task { @MainActor in
            vm.dragTargeted = true
            vm.open(tab: .shelf)
        }
    }

    func dropExited(info: DropInfo) {
        Task { @MainActor in
            vm.dragTargeted = false
            vm.scheduleClose(after: 0.8)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [UTType.fileURL])
        guard !providers.isEmpty else { return false }
        Task { @MainActor in
            shelf.add(from: providers)
            vm.dragTargeted = false
        }
        return true
    }
}
