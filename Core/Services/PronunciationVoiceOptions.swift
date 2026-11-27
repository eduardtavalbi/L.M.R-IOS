import Foundation

enum PronunciationVoiceOptions {
    static func availableVoices(for languageCode: String?) -> [String] {
        guard let languageCode, !languageCode.isEmpty else { return [] }
        guard languageCode.lowercased().hasPrefix("en") else { return [languageCode] }
        return ["en-US", "en-GB"]
    }

    static func defaultVoice(for languageCode: String?) -> String? {
        guard let languageCode, !languageCode.isEmpty else { return nil }
        if languageCode.lowercased().hasPrefix("en") {
            return languageCode.lowercased().contains("gb") ? "en-GB" : "en-US"
        }
        return languageCode
    }

    static func recognitionLocale(for languageCode: String?) -> String? {
        guard let languageCode, !languageCode.isEmpty else { return nil }
        let code = languageCode.lowercased()
        if code.hasPrefix("zh") { return "zh-CN" }
        if code.hasPrefix("en") { return code.contains("gb") ? "en-GB" : "en-US" }
        if code.hasPrefix("ja") { return "ja-JP" }
        if code.hasPrefix("ko") { return "ko-KR" }
        if code.hasPrefix("fr") { return "fr-FR" }
        if code.hasPrefix("de") { return "de-DE" }
        if code.hasPrefix("es") { return "es-ES" }
        if code.hasPrefix("ru") { return "ru-RU" }
        return languageCode
    }
}
