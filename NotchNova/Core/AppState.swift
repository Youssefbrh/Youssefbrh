import AppKit
import Combine

/// Owns every feature service and wires them together.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    let vm: NotchViewModel
    let shelf: ShelfStore
    let media: MediaController
    let stats: SystemStats
    let hud: VolumeBrightnessMonitor
    let alerts: AlertCenter
    let clipboard: ClipboardStore
    let pomodoro: PomodoroTimer
    let pet: PetEngine

    private var cancellables = Set<AnyCancellable>()

    private init() {
        vm = NotchViewModel()
        shelf = ShelfStore()
        media = MediaController()
        stats = SystemStats()
        hud = VolumeBrightnessMonitor()
        alerts = AlertCenter()
        clipboard = ClipboardStore()
        pomodoro = PomodoroTimer()
        pet = PetEngine()

        // Pet reacts to music.
        media.$isPlaying
            .removeDuplicates()
            .sink { [weak self] playing in
                Task { @MainActor in self?.pet.setDancing(playing) }
            }
            .store(in: &cancellables)

        // Pet gets startled by drops, alert confirms the stash.
        shelf.onItemAdded = { [weak self] name in
            self?.pet.startle()
            self?.alerts.post(icon: "tray.and.arrow.down.fill", title: "\(name) stashed", tint: .cyan)
        }

        // Timer completion → sneak alert.
        pomodoro.onPhaseCompleted = { [weak self] phase in
            switch phase {
            case .focus:
                self?.alerts.post(icon: "cup.and.saucer.fill", title: "Focus done — take a break", tint: .green)
            case .rest:
                self?.alerts.post(icon: "bolt.fill", title: "Break over — back to it", tint: .orange)
            }
        }

        // System warnings → sneak alerts.
        stats.onAlert = { [weak self] alert in
            switch alert {
            case .batteryLow(let pct):
                self?.alerts.post(icon: "battery.25percent", title: "Battery at \(pct)%", tint: .red)
            case .cpuHot:
                self?.alerts.post(icon: "flame.fill", title: "CPU running hot", tint: .orange)
            case .charging:
                self?.alerts.post(icon: "bolt.badge.clock", title: "Charging", tint: .green)
            }
        }

        // Volume / brightness changes → in-notch HUD.
        hud.onEvent = { [weak self] event in
            self?.vm.showHUD(event)
        }
    }

    func start() {
        media.start()
        stats.start()
        hud.start()
        clipboard.start()
        pet.start()
    }

    func stop() {
        media.stop()
        stats.stop()
        hud.stop()
        clipboard.stop()
        pet.stop()
        shelf.save()
    }
}
