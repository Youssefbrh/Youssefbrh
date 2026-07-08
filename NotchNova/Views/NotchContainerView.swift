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

    private var bottomRadius: CGFloat { isExpanded ? Theme.cornerRadius : 11 }
    private var shape: NotchShape { NotchShape(topRadius: topRadius, bottomRadius: bottomRadius) }

    var body: some View {
        ZStack(alignment: .top) {
            // Soft glow halo bleeding out from behind the island.
            AuroraGlowView(isExpanded: isExpanded)
                .frame(width: islandWidth + 80, height: islandHeight + 60)
                .allowsHitTesting(false)

            island

            if petEnabled, petPeeks, !isExpanded {
                PetView(size: 26, interactive: false)
                    .offset(x: pet.peekOffsetX, y: vm.geometry.notchHeight - 7)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var island: some View {
        ZStack(alignment: .top) {
            islandBackground

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
        .contentShape(shape)
        .onTapGesture {
            if !isExpanded { vm.open() }
        }
        .onDrop(of: [UTType.fileURL], delegate: NotchDropDelegate(vm: vm, shelf: shelf))
        .animation(vm.spring, value: isExpanded)
        .animation(vm.spring, value: wingExtra)
    }

    /// The premium surface: frosted glass + tint gradient + a bright top
    /// hairline that fades down the sides, plus a floating shadow. When
    /// closed it stays near-black so it melts into the hardware notch.
    @ViewBuilder
    private var islandBackground: some View {
        ZStack {
            if isExpanded {
                VisualEffectView(material: .hudWindow, blending: .behindWindow)
                    .clipShape(shape)
                shape.fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.black.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                shape.fill(Color.black.opacity(0.28))
            } else {
                shape.fill(Color.black)
            }
        }
        .overlay(
            shape.stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isExpanded ? 0.55 : 0.10),
                        Color.white.opacity(0.06),
                        Color.clear,
                    ],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(isExpanded ? 0.5 : 0), radius: 22, y: 12)
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
