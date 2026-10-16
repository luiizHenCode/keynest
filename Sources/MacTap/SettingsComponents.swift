import AppKit
import SwiftUI

enum SettingsPalette {
    static let accent = Color(red: 0.72, green: 0.95, blue: 0.57)
    static let canvas = Color(red: 0.065, green: 0.075, blue: 0.085)
    static let surface = Color.white.opacity(0.035)
    static let muted = Color.white.opacity(0.52)
}

struct SoftToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule()
                .fill(configuration.isOn ? SettingsPalette.accent : Color.white.opacity(0.15))
                .frame(width: 36, height: 22)
                .overlay {
                    Circle()
                        .fill(configuration.isOn ? SettingsPalette.canvas : Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: configuration.isOn ? 7 : -7)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: configuration.isOn)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .accessibilityValue(configuration.isOn ? L10n.tr("Ativado") : L10n.tr("Desativado"))
        }
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ButtonContent(configuration: configuration)
    }

    private struct ButtonContent: View {
        let configuration: ButtonStyleConfiguration
        @State private var isHovered = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.white.opacity(isHovered ? 0.07 : 0.035))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(Color.white.opacity(isHovered ? 0.16 : 0.07))
                }
                .contentShape(RoundedRectangle(cornerRadius: 11))
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: isHovered)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: configuration.isPressed)
                .onHover { isHovered = $0 }
        }
    }
}

// Place in the background of the ScrollView's content, not the ScrollView itself.
struct SettingsScrollStyle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ScrollProbe()
        view.attachLater()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollProbe)?.attachLater()
    }

    private final class ScrollProbe: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            attachLater()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            attachLater()
        }

        func attachLater() {
            DispatchQueue.main.async { [weak self] in
                guard let scrollView = self?.enclosingScrollView else { return }
                let preferredStyle = NSScroller.preferredScrollerStyle
                let useNativeScroller = preferredStyle == .legacy ||
                    NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                scrollView.scrollerStyle = preferredStyle
                scrollView.autohidesScrollers = preferredStyle == .overlay
                scrollView.drawsBackground = false
                scrollView.hasHorizontalScroller = false
                if useNativeScroller {
                    if scrollView.verticalScroller is ThinScroller {
                        scrollView.verticalScroller = NSScroller()
                    }
                } else if !(scrollView.verticalScroller is ThinScroller) {
                    scrollView.verticalScroller = ThinScroller()
                }
            }
        }
    }

    private final class ThinScroller: NSScroller {
        override class var isCompatibleWithOverlayScrollers: Bool { true }

        override func drawKnob() {
            let knob = rect(for: .knob)
            guard !knob.isEmpty else { return }
            let thinKnob = NSRect(x: knob.midX - 2, y: knob.minY, width: 4, height: knob.height)
            NSColor.white.withAlphaComponent(0.25).setFill()
            NSBezierPath(roundedRect: thinKnob, xRadius: 2, yRadius: 2).fill()
        }

        override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {}
    }
}
