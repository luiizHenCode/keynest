import SwiftUI

struct LanguagePickerView: View {
    @ObservedObject private var language = LanguageSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .foregroundStyle(SettingsPalette.accent).frame(width: 30, height: 30)
                    .background(SettingsPalette.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("Idioma")).font(.system(size: 14, weight: .semibold))
                    Text(L10n.tr("Use o idioma do sistema ou escolha o seu."))
                        .font(.system(size: 11)).foregroundStyle(SettingsPalette.muted)
                }
            }
            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { option in
                    Button { language.selection = option } label: {
                        HStack(spacing: 6) {
                            Text(option.title)
                            if language.selection == option {
                                Image(systemName: "checkmark").font(.system(size: 9, weight: .semibold))
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(language.selection == option ? SettingsPalette.accent : .white.opacity(0.7))
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(language.selection == option ? SettingsPalette.accent.opacity(0.08) : .white.opacity(0.025),
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(
                            language.selection == option ? SettingsPalette.accent.opacity(0.4) : .white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(language.selection == option ? .isSelected : [])
                }
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsPalette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.065)))
    }
}
