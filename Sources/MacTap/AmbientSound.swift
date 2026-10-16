import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case rain
    case ocean
    case forest
    case lofi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rain: return L10n.tr("Chuva")
        case .ocean: return L10n.tr("Oceano")
        case .forest: return L10n.tr("Floresta")
        case .lofi: return L10n.tr("Lo-fi · piano & beats")
        }
    }

    var subtitle: String {
        switch self {
        case .rain: return L10n.tr("Uma chuva tranquila para acompanhar o foco")
        case .ocean: return L10n.tr("Ondas do mar para desacelerar")
        case .forest: return L10n.tr("Pássaros e natureza ao fundo")
        case .lofi: return L10n.tr("Piano e batida leve · aproximadamente 79 BPM")
        }
    }

    var symbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .forest: return "tree.fill"
        case .lofi: return "music.note"
        }
    }

    // The music master is louder than the field recordings; avoid a jump when switching.
    var playbackGain: Float { self == .lofi ? 0.35 : 1 }

    var attribution: String {
        switch self {
        case .rain: return L10n.tr("alex36917 · edição Porrumentzio · loop adaptado")
        case .ocean: return L10n.tr("Luftrum · edição Porrumentzio · loop adaptado")
        case .forest: return L10n.tr("kvgarlic · edição Porrumentzio · loop adaptado")
        case .lofi: return L10n.tr("Chill lofi inspired · omfgdude · loop adaptado")
        }
    }

    var licenseTitle: String {
        switch self {
        case .rain, .ocean: return "CC BY 4.0"
        case .forest, .lofi: return "CC0 1.0"
        }
    }

    var licenseURL: URL {
        switch self {
        case .rain, .ocean: return URL(string: "https://creativecommons.org/licenses/by/4.0/")!
        case .forest, .lofi: return URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!
        }
    }

    var sourceURL: URL {
        switch self {
        case .rain: return URL(string: "https://freesound.org/people/alex36917/sounds/524605/")!
        case .ocean: return URL(string: "https://freesound.org/people/Luftrum/sounds/48412/")!
        case .forest: return URL(string: "https://freesound.org/people/kvgarlic/sounds/156826/")!
        case .lofi: return URL(string: "https://opengameart.org/content/chill-lofi-inspired")!
        }
    }
}
