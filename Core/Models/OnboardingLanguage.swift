import Foundation

struct OnboardingLanguage: Identifiable, Equatable {
    let name: String
    let code: String

    var id: String { code }

    static let suggested: [OnboardingLanguage] = [
        OnboardingLanguage(name: "中文 · Китайский", code: "zh"),
        OnboardingLanguage(name: "English · Английский", code: "en"),
        OnboardingLanguage(name: "日本語 · Японский", code: "ja"),
        OnboardingLanguage(name: "한국어 · Корейский", code: "ko"),
        OnboardingLanguage(name: "Español · Испанский", code: "es"),
        OnboardingLanguage(name: "Français · Французский", code: "fr"),
        OnboardingLanguage(name: "Deutsch · Немецкий", code: "de")
    ]
}
