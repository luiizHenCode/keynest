import SwiftUI

struct PomodoroView: View {
    @ObservedObject private var language = LanguageSettings.shared
    @ObservedObject var model: PomodoroModel
    @State private var confirmReset = false
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let accent = SettingsPalette.accent
    private var phaseColor: Color { model.session.phase == .rest ? Color(red: 0.56, green: 0.79, blue: 0.84) : accent }
    private var progress: Double {
        if model.session.state == .completed { return 1 }
        let duration = model.session.phase == .focus ? model.session.configuration.focusDuration : model.session.configuration.restDuration
        return min(1, max(0, 1 - model.session.remaining(at: model.now) / duration))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heading
            timerPanel
            sessionSummary
            if showSettings { settings }
            settingsButton
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20).fill(SettingsPalette.surface)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [phaseColor.opacity(0.055), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
        }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.075)))
        .confirmationDialog(L10n.tr("Reiniciar o Pomodoro?"), isPresented: $confirmReset) {
            Button(L10n.tr("Reiniciar sessão"), role: .destructive) { model.reset() }
            Button(L10n.tr("Cancelar"), role: .cancel) {}
        } message: { Text(L10n.tr("O progresso da sessão atual será descartado.")) }
        .alert(L10n.tr("Aviso do Pomodoro"), isPresented: Binding(
            get: { model.alertMessage != nil }, set: { if !$0 { model.alertMessage = nil } }
        )) { Button("OK") { model.alertMessage = nil } }
        message: { Text(model.alertMessage ?? "") }
    }

    private var heading: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer").font(.system(size: 15)).foregroundStyle(phaseColor)
                .frame(width: 30, height: 30)
                .background(phaseColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                Text("Pomodoro").font(.system(size: 14, weight: .semibold))
                Text(L10n.tr("Menos pressa. Mais presença."))
                    .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
            }
            Spacer()
            Text(model.session.state == .completed ? L10n.tr("Concluído") : model.cycleDescription)
                .font(.system(size: 10, weight: .medium)).foregroundStyle(SettingsPalette.muted)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.white.opacity(0.04), in: Capsule())
        }
    }

    private var timerPanel: some View {
        HStack(spacing: 26) {
            ZStack {
                Circle().strokeBorder(.white.opacity(0.055), lineWidth: 3)
                Circle().trim(from: 0, to: progress)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90)).padding(1.5)
                VStack(spacing: 7) {
                    Text(model.session.state == .completed ? L10n.tr("FEITO") : model.phaseTitle.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(2).foregroundStyle(phaseColor)
                    Text(model.countdown)
                        .font(.system(size: 33, weight: .light, design: .rounded))
                        .monospacedDigit().foregroundStyle(.white.opacity(0.95))
                        .minimumScaleFactor(0.7).lineLimit(1)
                }
                .padding(12)
            }
            .frame(width: 144, height: 144)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.tr("%@, %@ restantes", String(describing: model.phaseTitle), String(describing: model.countdown)))
            .accessibilityValue(L10n.tr("%@ por cento concluído", String(describing: Int(progress * 100))))

            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle)
                    .font(.system(size: 21, weight: .medium, design: .rounded)).tracking(-0.4)
                Text(heroSubtitle)
                    .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button { model.primaryAction() } label: {
                        Label(model.primaryTitle, systemImage: model.session.state == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SettingsPalette.canvas)
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            .background(phaseColor, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(PomodoroPressStyle())
                    if !model.canConfigure {
                        Button { confirmReset = true } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12)).frame(width: 14, height: 14)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .help(L10n.tr("Reiniciar sessão")).accessibilityLabel(L10n.tr("Reiniciar sessão"))
                    }
                }
                .padding(.top, 4)
                if model.canSkipRest {
                    Button(L10n.tr("Pular intervalo")) { model.skipRest() }
                        .buttonStyle(.plain).font(.system(size: 10))
                        .foregroundStyle(SettingsPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    private var heroTitle: String {
        switch model.session.state {
        case .idle: return L10n.tr("Uma coisa de cada vez.")
        case .paused: return L10n.tr("No seu ritmo.")
        case .completed: return L10n.tr("Tempo bem dedicado.")
        case .waiting: return model.session.phase == .rest ? L10n.tr("Uma pausa merecida.") : L10n.tr("Vamos de novo?")
        case .running: return model.session.phase == .rest ? L10n.tr("Solte os ombros.") : L10n.tr("Este momento é seu.")
        }
    }

    private var heroSubtitle: String {
        if let end = model.session.phaseEndDate {
            return L10n.tr("%@ até %@.", String(describing: model.phaseTitle), String(describing: L10n.time(end)))
        }
        switch model.session.state {
        case .idle: return L10n.tr("%@ minutos de foco, depois um respiro.", String(describing: model.plan.focusMinutes))
        case .paused: return L10n.tr("Seu tempo está guardado. Retome quando quiser.")
        case .waiting: return L10n.tr("A próxima etapa começa quando você estiver pronto.")
        case .completed: return L10n.tr("Você completou %@ ciclos. Bom trabalho.", String(describing: model.session.completedCycles))
        case .running: return model.stateTitle
        }
    }

    private var sessionSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                summaryItem(L10n.tr("FOCO"), value: "\(model.plan.focusMinutes) min")
                summaryDivider
                summaryItem(L10n.tr("PAUSA"), value: "\(model.plan.restMinutes) min")
                summaryDivider
                summaryItem(L10n.tr("TOTAL"), value: model.plan.totalPlannedDuration.map(PomodoroModel.duration) ?? L10n.tr("Sem limite"))
            }
            .padding(.vertical, 13)
            .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "clock").padding(.top, 1)
                Text(finishDescription).fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
        }
    }

    private func summaryItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 8, weight: .medium, design: .monospaced))
                .tracking(1.4).foregroundStyle(SettingsPalette.muted)
            Text(value).font(.system(size: 12, weight: .medium)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 16)
        .accessibilityElement(children: .combine)
    }

    private var summaryDivider: some View { Rectangle().fill(.white.opacity(0.07)).frame(width: 1, height: 26) }
    private var divider: some View { Rectangle().fill(.white.opacity(0.06)).frame(height: 1) }
    private var finishDescription: String {
        if model.session.state == .completed { return L10n.tr("Sessão concluída, incluindo o último intervalo.") }
        if model.session.state == .paused { return L10n.tr("Previsão atualizada ao retomar. Pausas não descontam seu tempo.") }
        if let finish = model.session.estimatedFinish(at: model.now) {
            return L10n.tr("Término previsto: %@.", String(describing: L10n.dateTime(finish)))
        }
        if model.plan.cycleLimit == nil { return L10n.tr("Sem horário final. Continue pelo tempo que fizer sentido.") }
        if model.plan.autoAdvance, let total = model.plan.totalPlannedDuration, model.session.state == .idle {
            return L10n.tr("Começando agora, termina %@.", String(describing: L10n.dateTime(model.now.addingTimeInterval(total))))
        }
        return L10n.tr("Você inicia cada etapa. O horário final acompanha suas pausas.")
    }

    private var settingsButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { showSettings.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                Text(showSettings ? L10n.tr("Fechar ajustes") : L10n.tr("Ajustar sessão"))
                Spacer()
                if !showSettings {
                    Text(model.plan.autoAdvance ? L10n.tr("Automático") : L10n.tr("No seu ritmo"))
                        .foregroundStyle(SettingsPalette.muted)
                }
                Image(systemName: showSettings ? "chevron.up" : "chevron.down").font(.system(size: 9, weight: .semibold))
            }
            .font(.system(size: 11, weight: .medium))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(QuietButtonStyle())
        .accessibilityValue(showSettings ? L10n.tr("Expandido") : L10n.tr("Recolhido"))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            divider
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    PomodoroNumberField(title: L10n.tr("Foco"), unit: "min", value: $model.focusMinutes, range: 1...180)
                    PomodoroNumberField(title: L10n.tr("Intervalo"), unit: "min", value: $model.restMinutes, range: 1...60)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.tr("REPETIÇÕES")).font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(1.2).foregroundStyle(SettingsPalette.muted)
                    HStack(spacing: 6) {
                        modeButton(L10n.tr("Definir ciclos"), symbol: "repeat", selected: !model.unlimited) { model.unlimited = false }
                        modeButton(L10n.tr("Sem limite"), symbol: "infinity", selected: model.unlimited) { model.unlimited = true }
                    }
                    if !model.unlimited {
                        PomodoroNumberField(title: L10n.tr("Quantidade de ciclos"), unit: L10n.tr("ciclos"), value: $model.cycleCount, range: 1...99)
                    }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("Seguir automaticamente")).font(.system(size: 11, weight: .medium))
                        Text(L10n.tr("Alterna foco e intervalo sem confirmação."))
                            .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                    }
                    Spacer()
                    Toggle(L10n.tr("Seguir automaticamente"), isOn: $model.autoAdvance).toggleStyle(SoftToggleStyle())
                }
            }
            .disabled(!model.canConfigure).opacity(model.canConfigure ? 1 : 0.5)
            Text(model.canConfigure
                 ? L10n.tr("Cada ciclo inclui foco + intervalo, inclusive o último.")
                 : L10n.tr("Tempos protegidos durante a sessão. Reinicie para editar."))
                .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
            divider
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("Modo live")).font(.system(size: 11, weight: .medium))
                    Text(L10n.tr("Acompanhe o tempo sem abrir os ajustes."))
                        .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                }
                Spacer()
                Toggle(L10n.tr("Modo live do Pomodoro"), isOn: $model.liveEnabled).toggleStyle(SoftToggleStyle())
            }
            if model.liveEnabled {
                HStack(spacing: 6) {
                    ForEach(PomodoroLiveStyle.allCases) { style in
                        modeButton(style.title, symbol: style.symbol, selected: model.liveStyle == style) {
                            model.liveStyle = style
                        }
                    }
                }
                Text(model.liveStyle == .menuBar
                     ? L10n.tr("Tempo na barra superior. Clique nele para iniciar etapas ou pular o intervalo.")
                     : L10n.tr("Painel sobre os apps, que expande ao terminar cada etapa."))
                    .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("Um toque ao terminar")).font(.system(size: 11, weight: .medium))
                    Text(L10n.tr("Sons diferentes para foco e intervalo."))
                        .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                }
                Spacer()
                Button { model.previewAlert() } label: { Image(systemName: "play.fill").font(.system(size: 10)) }
                    .buttonStyle(QuietButtonStyle()).accessibilityLabel(L10n.tr("Ouvir aviso"))
                Toggle(L10n.tr("Avisos sonoros"), isOn: $model.soundEnabled).toggleStyle(SoftToggleStyle())
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("Avisar por notificação")).font(.system(size: 11, weight: .medium))
                    Text(L10n.tr("Receba o lembrete mesmo fora desta janela."))
                        .font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                }
                Spacer()
                Toggle(L10n.tr("Notificações de foco e intervalo"), isOn: $model.notificationsEnabled)
                    .toggleStyle(SoftToggleStyle())
                    .onChange(of: model.notificationsEnabled) { _, enabled in
                        if enabled { model.authorizeNotifications() }
                    }
            }
            if model.notificationsEnabled {
                HStack {
                    Text(model.notificationStatus).font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                    Spacer()
                    Button(L10n.tr("Verificar acesso")) { model.authorizeNotifications() }
                        .buttonStyle(QuietButtonStyle()).font(.system(size: 10))
                }
            }
        }
    }

    private func modeButton(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selected ? accent : SettingsPalette.muted)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(selected ? accent.opacity(0.08) : .white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? accent.opacity(0.4) : .white.opacity(0.06)))
        }
        .buttonStyle(PomodoroPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct PomodoroNumberField: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("", text: $text)
                        .textFieldStyle(.plain).font(.system(size: 20, weight: .light, design: .rounded))
                        .monospacedDigit().frame(width: 44).focused($isFocused)
                        .onSubmit { commit(); isFocused = false }
                        .accessibilityLabel("\(title), \(unit)")
                    Text(unit).font(.system(size: 10)).foregroundStyle(SettingsPalette.muted)
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                adjustmentButton("plus", label: L10n.tr("Aumentar %@", String(describing: title)), disabled: value >= range.upperBound) {
                    commit(); value = min(range.upperBound, value + 1)
                }
                adjustmentButton("minus", label: L10n.tr("Diminuir %@", String(describing: title)), disabled: value <= range.lowerBound) {
                    commit(); value = max(range.lowerBound, value - 1)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isFocused ? SettingsPalette.accent.opacity(0.4) : .white.opacity(0.06)))
        .onAppear { text = String(value) }
        .onChange(of: value) { _, newValue in text = String(newValue) }
        .onChange(of: isFocused) { _, focused in if !focused { commit() } }
        .onDisappear { commit() }
    }

    private func commit() {
        value = min(range.upperBound, max(range.lowerBound, Int(text) ?? value))
        text = String(value)
    }

    private func adjustmentButton(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 9, weight: .medium))
                .foregroundStyle(SettingsPalette.muted).frame(width: 25, height: 22)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(PomodoroPressStyle()).disabled(disabled).opacity(disabled ? 0.3 : 1)
        .accessibilityLabel(label)
    }
}

private struct PomodoroPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}
