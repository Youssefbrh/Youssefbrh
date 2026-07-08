import SwiftUI

/// The opened island: content area for the selected tab + a compact tab bar.
struct ExpandedView: View {
    @EnvironmentObject var vm: NotchViewModel
    @Namespace private var tabNamespace

    @AppStorage(Prefs.Key.petEnabled.rawValue) private var petEnabled = true

    private var tabs: [NotchTab] {
        petEnabled ? NotchTab.allCases : NotchTab.allCases.filter { $0 != .pet }
    }

    var body: some View {
        VStack(spacing: 8) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .padding(.top, vm.geometry.notchHeight + 4)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch vm.selectedTab {
        case .home: HomeTabView()
        case .shelf: ShelfView()
        case .tools: ToolsTabView()
        case .pet: PetTabView()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                let selected = vm.selectedTab == tab
                Button {
                    withAnimation(vm.spring) { vm.selectedTab = tab }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                        if selected {
                            Text(tab.title)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Theme.accent.opacity(0.22))
                                .overlay(Capsule().stroke(Theme.accent.opacity(0.35), lineWidth: 0.5))
                                .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                        }
                    }
                    .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule().fill(Color.white.opacity(0.05))
        )
    }
}

struct HomeTabView: View {
    var body: some View {
        HStack(spacing: 14) {
            MediaView()
                .frame(maxWidth: .infinity)
            Divider()
                .overlay(Color.white.opacity(0.12))
            StatsView()
                .frame(width: 235)
        }
        .padding(.horizontal, 8)
    }
}

struct ToolsTabView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case clipboard = "Clipboard"
        case pomodoro = "Pomodoro"
        case mirror = "Mirror"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .clipboard: return "doc.on.clipboard"
            case .pomodoro: return "timer"
            case .mirror: return "web.camera"
            }
        }
    }

    @State private var tool: Tool = .clipboard

    var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $tool) {
                ForEach(Tool.allCases) { t in
                    Label(t.rawValue, systemImage: t.icon).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 320)

            Group {
                switch tool {
                case .clipboard: ClipboardView()
                case .pomodoro: PomodoroView()
                case .mirror: MirrorView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 8)
    }
}
