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
}
