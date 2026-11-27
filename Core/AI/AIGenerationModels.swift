import Foundation

struct AIGenerationRequest: Equatable {
    let topic: String
    let sourceLanguage: String
    let targetLanguage: String
    let level: String
    let count: Int

    func validate() throws {
        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !level.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (1...100).contains(count) else {
            throw AIGenerationError.invalidRequest
        }
    }
}

struct AIImportRequest: Equatable {
    let sourceText: String
    let sourceLanguage: String
    let targetLanguage: String
    let maxWords: Int

    func validate() throws {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              sourceText.count <= 30_000,
              !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (1...100).contains(maxWords) else {
            throw AIGenerationError.invalidRequest
        }
    }
}

struct AIEnrichmentRequest: Equatable {
    let words: [AIGeneratedWord]
    let sourceLanguage: String
    let targetLanguage: String

    func validate() throws {
        guard !words.isEmpty, words.count <= 100,
              !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              words.allSatisfy({
                  !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !$0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
            throw AIGenerationError.invalidRequest
        }
    }
}

struct AIGeneratedWord: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var translation: String
    var transcription: String?
    var example: String?
    var explanation: String?

    enum CodingKeys: String, CodingKey {
        case text, translation, transcription, example, explanation
    }

    init(
        id: UUID = UUID(),
        text: String,
        translation: String,
        transcription: String? = nil,
        example: String? = nil,
        explanation: String? = nil
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.transcription = transcription
        self.example = example
        self.explanation = explanation
    }
}


struct AIWeakWordAnalysisCard: Codable, Equatable {
    let id: String
    let text: String
    let translation: String
    let transcription: String?
    let correctAnswers: Int
    let incorrectAnswers: Int
    let streak: Int
    let intervalDays: Int
}

struct AIWeakWordAnalysisRequest: Equatable {
    let cards: [AIWeakWordAnalysisCard]
    let sourceLanguage: String
    let targetLanguage: String

    func validate() throws {
        guard !cards.isEmpty, cards.count <= 50,
              !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              cards.allSatisfy({
                  !$0.id.isEmpty &&
                  !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !$0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  $0.correctAnswers >= 0 && $0.incorrectAnswers > 0 &&
                  $0.streak >= 0 && $0.intervalDays >= 0
              }),
              Set(cards.map(\.id)).count == cards.count else {
            throw AIGenerationError.invalidRequest
        }
    }
}

struct AIWeakWordInsight: Codable, Equatable, Identifiable {
    let id: String
    let word: String
    let translation: String
    let difficultyReason: String
    let recommendation: String
    let practicePrompt: String
}

enum AIGenerationError: LocalizedError, Equatable {
    case invalidRequest
    case missingAPIKey
    case invalidResponse
    case requestFailed(String)
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Проверь входные данные и ограничения запроса."
        case .missingAPIKey:
            return "Сначала добавь Gemini API-ключ в настройках AI."
        case .invalidResponse:
            return "AI вернул ответ в неподдерживаемом формате. Попробуй ещё раз."
        case .requestFailed(let message):
            return message
        case .serviceUnavailable:
            return "Сервис AI временно недоступен. Попробуй позже."
        }
    }
}

protocol AIGenerationProvider {
    var identifier: String { get }
    func generateVocabulary(for request: AIGenerationRequest) async throws -> [AIGeneratedWord]
    func extractVocabulary(from request: AIImportRequest) async throws -> [AIGeneratedWord]
}
