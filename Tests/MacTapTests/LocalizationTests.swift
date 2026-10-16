import XCTest
@testable import MacTap

final class LocalizationTests: XCTestCase {
    func testSloganAndCoreLabelsInBothLanguages() {
        XCTAssertEqual(L10n.translate("Encontre seu foco.", language: .portuguese), "Encontre seu foco.")
        XCTAssertEqual(L10n.translate("Encontre seu foco.", language: .english), "Find your focus.")
        XCTAssertEqual(L10n.translate("Iniciar intervalo", language: .english), "Start break")
        XCTAssertEqual(L10n.translate("Teclado", language: .english), "Keyboard")
        XCTAssertEqual(L10n.translate("Idioma", language: .english), "Language")
        XCTAssertEqual(L10n.translate("Abrir Keynest", language: .english), "Open Keynest")
    }

    func testInterpolationAndLiteralPercentArePreserved() {
        XCTAssertEqual(L10n.translate("Ciclo %@ de %@", arguments: ["2", "4"], language: .english), "Cycle 2 of 4")
        XCTAssertEqual(L10n.translate("Ciclo %@ de %@", arguments: ["2", "4"], language: .portuguese), "Ciclo 2 de 4")
        XCTAssertEqual(L10n.translate("Volume do ambiente · %@%%", arguments: ["25"], language: .english), "Ambience volume · 25%")
        XCTAssertEqual(L10n.translate("100% local", language: .portuguese), "100% local")
        XCTAssertEqual(L10n.translate("Gravação %@.wav ausente. Recompile o aplicativo com seus recursos de áudio.",
                                      arguments: ["a%name"], language: .english),
                       "Recording a%name.wav is missing. Rebuild the app with its audio resources.")
    }

    func testSystemLanguageResolutionAndFallback() {
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["pt-BR"]), "pt-BR")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["pt-PT"]), "pt-BR")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["en-GB", "pt-BR"]), "en")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["fr-FR", "pt-BR"]), "pt-BR")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["ja"]), "en")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: []), "en")
        XCTAssertEqual(AppLanguage.english.resolvedCode(preferredLanguages: ["pt-BR"]), "en")
    }

    @MainActor
    func testSelectionPersistsAndLanguageChangeDoesNotResetPomodoro() throws {
        let name = "Keynest.LocalizationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let language = LanguageSettings(defaults: defaults)
        XCTAssertEqual(language.selection, .system)
        let pomodoro = PomodoroModel(defaults: defaults)
        pomodoro.soundEnabled = false
        pomodoro.primaryAction()
        let original = pomodoro.session
        language.selection = .english
        XCTAssertEqual(LanguageSettings(defaults: defaults).selection, .english)
        XCTAssertEqual(pomodoro.session, original)
        language.selection = .portuguese
        XCTAssertEqual(LanguageSettings(defaults: defaults).selection, .portuguese)
        XCTAssertEqual(pomodoro.session, original)
    }

    func testCatalogsHaveMatchingKeysAndFormatArguments() throws {
        func catalog(_ language: AppLanguage) throws -> [String: String] {
            let bundle = try XCTUnwrap(L10n.bundle(for: language))
            let url = try XCTUnwrap(bundle.url(forResource: "Localizable", withExtension: "strings"))
            let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
            return try XCTUnwrap(plist as? [String: String])
        }
        let portuguese = try catalog(.portuguese)
        let english = try catalog(.english)
        XCTAssertGreaterThanOrEqual(portuguese.count, 189)
        XCTAssertEqual(Set(portuguese.keys), Set(english.keys))
        for (key, value) in english {
            XCTAssertFalse(value.isEmpty, key)
            XCTAssertFalse(value.contains("Tapora"), key)
            XCTAssertEqual(key.components(separatedBy: "%@").count,
                           value.components(separatedBy: "%@").count, key)
        }
        let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/MacTap")
        let expression = try NSRegularExpression(pattern: #"L10n\.tr\("([^"\n]+)""#)
        for url in try FileManager.default.contentsOfDirectory(at: sourceRoot, includingPropertiesForKeys: nil)
            where url.pathExtension == "swift" {
            let source = try String(contentsOf: url, encoding: .utf8)
            for match in expression.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                let range = try XCTUnwrap(Range(match.range(at: 1), in: source))
                XCTAssertNotNil(english[String(source[range])], "Missing translation in \(url.lastPathComponent): \(source[range])")
            }
        }
    }
}
