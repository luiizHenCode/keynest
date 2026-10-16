import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case portuguese = "pt-BR"
    case english = "en"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return L10n.tr("Sistema")
        case .portuguese: return "Português"
        case .english: return "English"
        }
    }

    func resolvedCode(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        if self != .system { return rawValue }
        for preferred in preferredLanguages {
            let code = preferred.lowercased()
            if code == "pt" || code.hasPrefix("pt-") { return "pt-BR" }
            if code == "en" || code.hasPrefix("en-") { return "en" }
        }
        return "en"
    }
}

extension Notification.Name {
    static let appLanguageChanged = Notification.Name("keynest.languageChanged")
}

final class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()
    private let defaults: UserDefaults
    @Published var selection: AppLanguage {
        didSet {
            defaults.set(selection.rawValue, forKey: "app.language")
            NotificationCenter.default.post(name: .appLanguageChanged, object: self)
        }
    }
    var locale: Locale { Locale(identifier: selection.resolvedCode()) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selection = AppLanguage(rawValue: defaults.string(forKey: "app.language") ?? "") ?? .system
    }
}

private final class LocalizationBundleFinder {}

enum L10n {
    static var locale: Locale { LanguageSettings.shared.locale }

    private static let resources: Bundle? = {
        let candidates = [Bundle.main.resourceURL, Bundle(for: LocalizationBundleFinder.self).resourceURL,
                          Bundle.main.bundleURL, Bundle.main.executableURL?.deletingLastPathComponent()]
        return candidates.compactMap { location in
            location.flatMap { Bundle(url: $0.appendingPathComponent("MacTap_MacTap.bundle")) }
        }.first
    }()

    private static let localizedBundles: [String: Bundle] = {
        var result: [String: Bundle] = [:]
        for code in ["pt-BR", "en"] {
            if let path = resources?.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) {
                result[code] = bundle
            }
        }
        return result
    }()

    static func bundle(for language: AppLanguage) -> Bundle? {
        localizedBundles[language.resolvedCode()]
    }

    static func tr(_ key: String, _ arguments: String...) -> String {
        translate(key, arguments: arguments, language: LanguageSettings.shared.selection)
    }

    static func translate(_ key: String, arguments: [String] = [], language: AppLanguage) -> String {
        let format = bundle(for: language)?.localizedString(forKey: key, value: key, table: "Localizable") ?? key
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language.resolvedCode()), arguments: arguments)
    }

    static func time(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale))
    }
}
