import AppKit
import Combine
import QuartzCore
import SwiftUI

enum PomodoroLiveLayout {
  static let inset: CGFloat = 20
  static let controlSize: CGFloat = 36
  static let animationDuration: TimeInterval = 0.24

  static func size(expanded: Bool) -> NSSize {
    NSSize(width: 360, height: expanded ? 252 : 82)
  }
}

/// Owned by the app delegate, not by a settings view that can disappear.
@MainActor
final class PomodoroLiveController {
  private var panel: LivePanel?
  private var observation: AnyCancellable?
  private weak var model: PomodoroModel?
  private var expanded: Bool?
  private var screenObserver: AnyCancellable?

  func connect(to model: PomodoroModel) {
    guard self.model !== model else { return }
    self.model = model
    observation = model.objectWillChange
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in self?.update() }
    screenObserver = NotificationCenter.default.publisher(
      for: NSApplication.didChangeScreenParametersNotification
    )
    .receive(on: RunLoop.main).sink { [weak self] _ in self?.keepOnScreen() }
    update()
  }

  private func update() {
    guard let model else { return }
    guard model.floatingLiveVisible else {
      panel?.orderOut(nil)
      return
    }
    if panel == nil {
      let panel = LivePanel(
        contentRect: NSRect(
          origin: .zero, size: PomodoroLiveLayout.size(expanded: model.liveExpanded)),
        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)

      panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
      panel.isOpaque = false
      panel.backgroundColor = .clear
      panel.hasShadow = true
      panel.isMovableByWindowBackground = true
      panel.hidesOnDeactivate = false
      panel.isReleasedWhenClosed = false
      let hostingView = NSHostingView(rootView: PomodoroLiveView(model: model))
      // The controller owns window sizing. An unconstrained hosting view can propagate
      // its changing intrinsic limits back to NSPanel and grow the window indefinitely.
      hostingView.sizingOptions = []
      panel.contentView = hostingView
      panel.contentMinSize = PomodoroLiveLayout.size(expanded: false)
      panel.contentMaxSize = PomodoroLiveLayout.size(expanded: true)
      let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
      panel.setFrameTopLeftPoint(
        NSPoint(x: visible.maxX - panel.frame.width - 24, y: visible.maxY - 24))
      self.panel = panel
    }
    guard let panel else { return }
    let desiredLevel: NSWindow.Level = model.livePinned ? .floating : .normal
    if panel.level != desiredLevel { panel.level = desiredLevel }
    let size = PomodoroLiveLayout.size(expanded: model.liveExpanded)
    if expanded != model.liveExpanded || panel.frame.size != size {
      let top = panel.frame.maxY
      let frame = NSRect(
        x: panel.frame.maxX - size.width, y: top - size.height,
        width: size.width, height: size.height)
      let animate = panel.isVisible && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      // Don't set min/max to the destination size before animating: AppKit would
      // constrain the current frame immediately and skip the visible transition.
      expanded = model.liveExpanded
      if animate {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = PomodoroLiveLayout.animationDuration
          context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
          panel.animator().setFrame(frame, display: true)
        }
      } else {
        panel.setFrame(frame, display: true)
      }
    }
    if !panel.isVisible { panel.orderFrontRegardless() }
    keepOnScreen()
  }

  private func keepOnScreen() {
    guard let panel, panel.isVisible else { return }
    let screen = panel.screen ?? NSScreen.main
    guard let bounds = screen?.visibleFrame else { return }
    var frame = panel.frame
    frame.origin.x = min(max(frame.minX, bounds.minX + 8), bounds.maxX - frame.width - 8)
    frame.origin.y = min(max(frame.minY, bounds.minY + 8), bounds.maxY - frame.height - 8)
    if frame != panel.frame { panel.setFrame(frame, display: true) }
  }
}

/// Explicit native dragging avoids relying on SwiftUI hosting-view background hit testing.
struct LivePanelDragHandle: NSViewRepresentable {
  func makeNSView(context: Context) -> DragView { DragView() }
  func updateNSView(_ nsView: DragView, context: Context) {}

  final class DragView: NSView {
    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
      window?.performDrag(with: event)
    }
    override func resetCursorRects() {
      addCursorRect(bounds, cursor: .openHand)
    }
  }
}

private struct LivePanelControlStyle: ButtonStyle {
  let accent: Color
  let selected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(selected ? accent : Color.white.opacity(0.65))
      .frame(width: PomodoroLiveLayout.controlSize, height: PomodoroLiveLayout.controlSize)
      .background(
        selected ? accent.opacity(0.1) : .white.opacity(0.045),
        in: RoundedRectangle(cornerRadius: 10)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10).strokeBorder(
          selected ? accent.opacity(0.18) : .white.opacity(0.07))
      )
      .contentShape(RoundedRectangle(cornerRadius: 10))
      .opacity(configuration.isPressed ? 0.65 : 1)
  }
}

private struct LivePanelActionStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, 14).frame(height: 36)
      .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
      .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.08)))
      .contentShape(RoundedRectangle(cornerRadius: 10))
      .opacity(configuration.isPressed ? 0.65 : 1)
  }
}

private final class LivePanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}

struct PomodoroLiveView: View {
  @ObservedObject private var language = LanguageSettings.shared
  @ObservedObject var model: PomodoroModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var accent: Color {
    model.session.phase == .rest
      ? Color(red: 0.56, green: 0.79, blue: 0.84) : SettingsPalette.accent
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        HStack(spacing: 10) {
          Image(systemName: model.session.state == .completed ? "checkmark.circle" : "timer")
            .font(.system(size: 18)).foregroundStyle(accent)
          VStack(alignment: .leading, spacing: 4) {
            Text(model.session.state == .completed ? L10n.tr("Sessão concluída") : model.phaseTitle)
              .font(.system(size: 11, weight: .medium))
            Text(model.cycleDescription)
              .font(.system(size: 9)).foregroundStyle(SettingsPalette.muted)
          }
          Spacer(minLength: 4)
          if !model.liveExpanded {
            Text(model.countdown).font(.system(size: 23, weight: .light, design: .rounded))
              .monospacedDigit().foregroundStyle(accent)
              .accessibilityLabel(L10n.tr("%@ restantes", String(describing: model.countdown)))
          }
        }
        .frame(maxWidth: .infinity)
        .overlay(LivePanelDragHandle())
        .help(L10n.tr("Arraste aqui para mover o timer"))
        Button {
          model.livePinned.toggle()
        } label: {
          Image(systemName: model.livePinned ? "pin.fill" : "pin.slash")
            .font(.system(size: 12, weight: .medium))
        }
        .buttonStyle(LivePanelControlStyle(accent: accent, selected: model.livePinned))
        .help(
          model.livePinned
            ? L10n.tr("Desafixar: permitir que outras janelas cubram o timer")
            : L10n.tr("Fixar o timer sobre as outras janelas")
        )
        .accessibilityLabel(L10n.tr("Fixar no topo"))
        .accessibilityValue(model.livePinned ? L10n.tr("Ativado") : L10n.tr("Desativado"))
        Button {
          model.liveExpanded.toggle()
        } label: {
          Image(systemName: "chevron.down")
            .font(.system(size: 11, weight: .semibold))
            .rotationEffect(.degrees(model.liveExpanded ? 180 : 0))
        }
        .buttonStyle(LivePanelControlStyle(accent: accent, selected: false))
        .accessibilityLabel(model.liveExpanded ? L10n.tr("Recolher painel") : L10n.tr("Expandir painel"))
      }
      .frame(height: 40)
      if model.liveExpanded {
        VStack(alignment: .leading, spacing: 12) {
          VStack(alignment: .leading, spacing: 6) {
            Text(model.stateTitle)
              .font(.system(size: 19, weight: .medium, design: .rounded))
            Text(detail)
              .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
              .fixedSize(horizontal: false, vertical: true)
          }
          HStack(spacing: 8) {
            Button {
              model.continueFromLive()
            } label: {
              Text(actionTitle).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SettingsPalette.canvas)
                .padding(.horizontal, 14).frame(height: 36)
                .background(accent, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            if model.canSkipRest {
              Button(L10n.tr("Pular intervalo")) { model.skipRest() }
                .buttonStyle(LivePanelActionStyle()).font(.system(size: 11))
            } else if model.session.state == .running {
              Button(L10n.tr("Pausar")) { model.primaryAction() }
                .buttonStyle(LivePanelActionStyle()).font(.system(size: 11))
            }
          }
          Spacer(minLength: 0)
          HStack {
            Label(L10n.tr("Arraste pelo cabeçalho"), systemImage: "hand.draw")
              .font(.system(size: 9))
              .overlay(LivePanelDragHandle())
            Spacer()
            Button(L10n.tr("Ocultar")) { model.liveEnabled = false }
              .buttonStyle(.plain).font(.system(size: 9))
              .help(L10n.tr("Reative o modo live nos ajustes ou na barra de menus"))
          }
          .foregroundStyle(SettingsPalette.muted)
          .frame(height: 20)
        }
        .transition(.opacity)
      }
    }
    .padding(PomodoroLiveLayout.inset)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SettingsPalette.canvas.opacity(0.97), in: RoundedRectangle(cornerRadius: 17))
    .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(accent.opacity(0.22)))
    .padding(1)
    .clipped()
    .animation(
      reduceMotion ? nil : .easeInOut(duration: PomodoroLiveLayout.animationDuration),
      value: model.liveExpanded
    )
    .preferredColorScheme(.dark)
    .environment(\.locale, language.locale)
  }

  private var actionTitle: String {
    switch model.session.state {
    case .running: return model.session.phase == .rest ? L10n.tr("Continuar intervalo") : L10n.tr("Continuar foco")
    case .paused: return L10n.tr("Retomar")
    case .completed: return L10n.tr("Nova sessão")
    default: return model.session.phase == .rest ? L10n.tr("Iniciar intervalo") : L10n.tr("Iniciar ciclo")
    }
  }

  private var detail: String {
    switch model.session.state {
    case .waiting:
      return model.session.phase == .rest
        ? L10n.tr("Respire um pouco. A pausa começa quando você quiser.")
        : L10n.tr("Intervalo encerrado. Pronto para mais um ciclo?")
    case .completed: return L10n.tr("Bom trabalho. Todos os ciclos foram concluídos.")
    case .paused: return L10n.tr("Seu tempo está guardado. Retome quando quiser.")
    default: return L10n.tr("%@ restantes. Você pode continuar em outro app.", String(describing: model.countdown))
    }
  }
}
