import SwiftUI
import AVFoundation

@main
struct MacTapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @StateObject private var pomodoro = PomodoroModel()

    init() {
        // Verify the actual packaged app, not just resources in SwiftPM's build directory.
        if CommandLine.arguments.contains("--check-resources") {
            do {
                for sound in ClickSound.allCases {
                    for variation in 0..<ClickSound.variationCount {
                        _ = try sound.loadBuffer(variation: variation)
                    }
                }
                for sound in AmbientSound.allCases {
                    let file = try AVAudioFile(forReading: AmbientAudio.recordingURL(sound: sound))
                    guard file.length > 0 else { exit(1) }
                }
                guard L10n.bundle(for: .portuguese) != nil,
                      L10n.bundle(for: .english) != nil,
                      L10n.translate("Encontre seu foco.", language: .english) == "Find your focus." else {
                    print("Falha: catálogos de idioma ausentes no aplicativo.")
                    exit(1)
                }
                print("OK: Keynest · 12 gravações de teclas, \(AmbientSound.allCases.count) trilhas ambiente e idiomas português/inglês carregados do aplicativo.")
                exit(0)
            } catch {
                print("Falha nos recursos de áudio: \(error.localizedDescription)")
                exit(1)
            }
        }
    }

    var body: some Scene {
        Window("Keynest", id: "main") {
            ContentView(model: model, pomodoro: pomodoro)
                .background(MainWindowLifecycle())
                .background(StatusBarConnection(controller: appDelegate.statusBar, model: model, pomodoro: pomodoro))
                .onAppear { appDelegate.pomodoroLive.connect(to: pomodoro) }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 740)
        .defaultPosition(.center)
    }
}

private struct StatusBarConnection: View {
    let controller: StatusBarController
    let model: AppModel
    let pomodoro: PomodoroModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.onAppear {
            controller.connect(model: model, pomodoro: pomodoro) {
                NSApplication.shared.setActivationPolicy(.regular)
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}
