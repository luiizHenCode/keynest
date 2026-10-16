import SwiftUI

struct ContentView: View {
    @ObservedObject private var language = LanguageSettings.shared
    @ObservedObject var model: AppModel
    @ObservedObject var pomodoro: PomodoroModel
    @State private var testText = ""
    @FocusState private var isTestFocused: Bool
    private let accent = SettingsPalette.accent

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PomodoroView(model: pomodoro)
                    keyboardSection
                    ambientSection
                    LanguagePickerView()
                    testSection
                    if !model.hasPermission || (model.isEnabled && !model.isMonitoring) {
                        permissionCard
                    }
                }
                .padding(28)
                .background(SettingsScrollStyle())
            }
            .scrollContentBackground(.hidden)
            separator
            footer
        }
        .frame(width: 640)
        .frame(minHeight: 520, idealHeight: 740, maxHeight: 900)
        .background {
            LinearGradient(
                colors: [Color(red: 0.105, green: 0.12, blue: 0.13), SettingsPalette.canvas],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, language.locale)
        .tint(accent)
        .onChange(of: isTestFocused) { _, focused in model.isTestingKeyboard = focused }
        .onDisappear {
            testText = ""
            model.isTestingKeyboard = false
        }
        .alert(L10n.tr("Não foi possível reproduzir ou monitorar"), isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private var header: some View {
        HStack(spacing: 13) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().interpolation(.high)
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Keynest")
                    .font(.system(size: 25, weight: .semibold, design: .rounded)).tracking(-0.7)
                Text(L10n.tr("Encontre seu foco."))
                    .font(.system(size: 12)).foregroundStyle(SettingsPalette.muted)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 5, height: 5)
                Text(model.status).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(statusColor.opacity(0.07), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.tr("Teclado: %@", String(describing: model.status)))
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 22)
    }

    private var statusColor: Color {
        if !model.isEnabled { return SettingsPalette.muted }
        return model.isMonitoring ? accent : .orange
    }

    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionHeading(L10n.tr("Teclado"), subtitle: L10n.tr("Um toque de personalidade."), symbol: "keyboard")
                Spacer()
                Toggle(L10n.tr("Ativar sons do teclado"), isOn: $model.isEnabled)
                    .toggleStyle(SoftToggleStyle())
                    .help(L10n.tr("Ativar ou pausar os cliques do teclado"))
            }
            HStack(spacing: 10) {
                ForEach(ClickSound.allCases) { sound in
                    SoundChoiceTile(
                        title: sound.title.replacingOccurrences(of: "Cherry ", with: ""),
                        detail: sound.subtitle,
                        symbol: "keyboard",
                        isSelected: model.sound == sound
                    ) {
                        model.sound = sound
                        model.preview(sound)
                    }
                    .accessibilityLabel(L10n.tr("%@. %@. Ouvir exemplo", String(describing: sound.title), String(describing: sound.subtitle)))
                }
            }
            HStack(spacing: 14) {
                volumeControl(L10n.tr("Volume dos cliques"), value: $model.volume)
                Button { model.preview() } label: {
                    Label(L10n.tr("Ouvir"), systemImage: "play.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(QuietButtonStyle())
                .help(L10n.tr("Ouvir o teclado no volume escolhido"))
            }
        }
        .padding(20)
        .modifier(SettingsPanel())
    }

    private var ambientSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionHeading(L10n.tr("Ambiente"), subtitle: L10n.tr("Um respiro ao fundo."), symbol: "headphones")
                Spacer()
                Toggle(L10n.tr("Ativar trilha ambiente"), isOn: $model.isAmbientEnabled)
                    .toggleStyle(SoftToggleStyle())
                    .help(L10n.tr("O ambiente funciona independentemente dos cliques"))
            }
            HStack(spacing: 8) {
                ForEach(AmbientSound.allCases) { sound in
                    SoundChoiceTile(
                        title: sound == .lofi ? "Lo-fi" : sound.title,
                        detail: nil,
                        symbol: sound.symbol,
                        isSelected: model.ambientSound == sound
                    ) { model.ambientSound = sound }
                    .help(sound.subtitle)
                    .accessibilityLabel("\(sound.title). \(sound.subtitle)")
                }
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: model.isAmbientEnabled ? "waveform" : "pause.circle")
                    .foregroundStyle(model.isAmbientEnabled ? accent : SettingsPalette.muted)
                    .frame(width: 14)
                Text(model.ambientSound.subtitle)
                    .foregroundStyle(SettingsPalette.muted)
                Spacer(minLength: 0)
                Text(model.isAmbientEnabled ? L10n.tr("Em loop") : L10n.tr("Pausado"))
                    .foregroundStyle(model.isAmbientEnabled ? accent : SettingsPalette.muted)
            }
            .font(.system(size: 10))
            volumeControl(L10n.tr("Volume do ambiente"), value: $model.ambientVolume)
            HStack(alignment: .top, spacing: 8) {
                Text(model.ambientSound.attribution)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Link(L10n.tr("Fonte"), destination: model.ambientSound.sourceURL)
                Link(model.ambientSound.licenseTitle, destination: model.ambientSound.licenseURL)
            }
            .font(.system(size: 9)).foregroundStyle(SettingsPalette.muted)
        }
        .padding(20)
        .modifier(SettingsPanel())
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.tr("Experimente")).font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(L10n.tr("%@ toques", String(describing: model.detectedKeyCount)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(SettingsPalette.muted)
                    .monospacedDigit()
            }
            HStack(spacing: 10) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(isTestFocused ? accent : SettingsPalette.muted)
                TextField(L10n.tr("Dê um toque. Ou vários…"), text: $testText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isTestFocused)
                    .accessibilityLabel(L10n.tr("Área para experimentar os sons do teclado"))
                    .onChange(of: testText) { _, _ in
                        if testText.count > 120 { testText = "" }
                    }
                if !testText.isEmpty {
                    Button { testText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(SettingsPalette.muted)
                    }
                    .buttonStyle(.plain).accessibilityLabel(L10n.tr("Limpar texto de teste"))
                }
            }
            .padding(14)
            .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                isTestFocused ? accent.opacity(0.5) : .white.opacity(0.08)
            ))
            Text(model.volume == 0
                 ? L10n.tr("O volume dos cliques está zerado. Aumente para ouvir o teste.")
                 : L10n.tr("Funciona mesmo em pausa. O texto não é salvo."))
                .font(.system(size: 10))
                .foregroundStyle(model.volume == 0 ? Color.orange : SettingsPalette.muted)
        }
        .padding(.horizontal, 2)
    }

    private func sectionHeading(_ title: String, subtitle: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15)).foregroundStyle(accent.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
            }
        }
    }

    private func volumeControl(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: value.wrappedValue == 0 ? "speaker.slash" : "speaker.wave.1")
                .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
                .frame(width: 14)
            Slider(value: value, in: 0...1)
                .controlSize(.small)
                .accessibilityLabel(label)
                .accessibilityValue(L10n.tr("%@ por cento", String(describing: Int(value.wrappedValue * 100))))
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .monospacedDigit().foregroundStyle(SettingsPalette.muted)
                .frame(width: 34, alignment: .trailing)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.tr("Leve os cliques para outros apps"), systemImage: "hand.raised")
                .font(.system(size: 12, weight: .medium))
            Text(L10n.tr("Autorize o Keynest em Privacidade e Segurança → Monitoramento de Entrada. Se já autorizou, encerre e reabra o app."))
                .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(L10n.tr("Autorizar no macOS")) { model.requestPermission() }
                    .buttonStyle(QuietButtonStyle())
                Button(L10n.tr("Abrir Ajustes")) { model.openPrivacySettings() }
                    .buttonStyle(.link)
            }
            .font(.system(size: 11))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .modifier(SettingsPanel())
    }

    private var separator: some View { Rectangle().fill(.white.opacity(0.06)).frame(height: 1) }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "menubar.rectangle")
            Text(L10n.tr("Continua na barra de menus ao fechar"))
            Spacer()
            Image(systemName: "lock.shield")
            Text(L10n.tr("100% local"))
        }
        .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
        .padding(.horizontal, 28).padding(.vertical, 14)
    }
}

private struct SettingsPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SettingsPalette.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.065)))
    }
}

private struct SoundChoiceTile: View {
    let title: String
    let detail: String?
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: symbol).font(.system(size: 18, weight: .regular))
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 10))
                        .opacity(isSelected ? 1 : 0.2)
                }
                .foregroundStyle(isSelected ? SettingsPalette.accent : Color.white.opacity(0.6))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                    if let detail {
                        Text(detail).font(.system(size: 10))
                            .foregroundStyle(SettingsPalette.muted)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: detail == nil ? 78 : 112)
            .background(
                isSelected ? SettingsPalette.accent.opacity(0.07) : .white.opacity(isHovered ? 0.055 : 0.015),
                in: RoundedRectangle(cornerRadius: 13)
            )
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(
                isSelected ? SettingsPalette.accent.opacity(0.55) : .white.opacity(isHovered ? 0.18 : 0.07)
            ))
            .contentShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: isHovered)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
