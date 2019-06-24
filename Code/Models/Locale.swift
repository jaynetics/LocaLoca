import Foundation

struct Locale {
    var code: String

    var nameWithFlag: String {
        if let flag = emojiFlag { return "\(flag) \(code)" }
        else                    { return code }
    }
    
    // based on Flag.swift from LocalizationEditor by Igor Kulman
    // https://github.com/igorkulman/iOSLocalizationEditor
    private var emojiFlag: String? {
        let language = String(code.split(separator: "-").first ?? "")
        switch language {
        case "ar": return "🇱🇧"
        case "ca": return nil // no emoji flag
        case "cs": return "🇨🇿"
        case "da": return "🇩🇰"
        case "de": return "🇩🇪"
        case "el": return "🇬🇷"
        case "en": return "🇬🇧"
        case "es": return "🇪🇸"
        case "fi": return "🇫🇮"
        case "fr": return "🇫🇷"
        case "he": return "🇮🇱"
        case "hi": return "🇮🇳"
        case "hr": return "🇭🇷"
        case "hu": return "🇭🇺"
        case "id": return "🇮🇩"
        case "it": return "🇮🇹"
        case "ja": return "🇯🇵"
        case "ms": return "🇲🇾"
        case "nb": return "🇳🇴"
        case "nl": return "🇳🇱"
        case "pl": return "🇵🇱"
        case "pt": return "🇵🇹"
        case "ro": return "🇷🇴"
        case "ru": return "🇷🇺"
        case "sk": return "🇸🇰"
        case "sv": return "🇸🇪"
        case "th": return "🇹🇭"
        case "tr": return "🇹🇷"
        case "uk": return "🇺🇦"
        case "vi": return "🇻🇳"
        case "zh": return "🇨🇳"
        default:   return emojiFlag(countryCode: language)
        }
    }
    
    private func emojiFlag(countryCode: String) -> String? {
        guard countryCode.count == 2 else { return nil }
        var string = ""
        for unicodeScalar in countryCode.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(0x1F1A5 + unicodeScalar.value) {
                string.append(String(scalar))
            }
        }
        return string.isEmpty ? nil : string
    }
}
