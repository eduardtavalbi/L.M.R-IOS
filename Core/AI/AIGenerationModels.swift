import Foundation
struct AIGenerationRequest: Equatable {
 let topic: String; let sourceLanguage: String; let targetLanguage: String; let level: String; let count: Int
 func validate() throws {
  guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
   !sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
   !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
   !level.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, (1...100).contains(count)
  else { throw AIGenerationError.invalidRequest }
 }
}
struct AIGeneratedWord: Codable, Equatable, Identifiable {
 var id: UUID = UUID(); var text: String; var translation: String
 var transcription: String?; var example: String?; var explanation: String?
 enum CodingKeys: String, CodingKey { case text, translation, transcription, example, explanation }
 init(id: UUID = UUID(), text: String, translation: String, transcription: String? = nil, example: String? = nil, explanation: String? = nil) {
  self.id=id; self.text=text; self.translation=translation; self.transcription=transcription; self.example=example; self.explanation=explanation
 }
}
enum AIGenerationError: LocalizedError, Equatable {
 case invalidRequest, missingAPIKey, invalidResponse, requestFailed(String), serviceUnavailable
 var errorDescription: String? {
  switch self {
  case .invalidRequest: return "Проверь тему, языки, уровень и количество карточек (от 1 до 100)."
  case .missingAPIKey: return "Сначала добавь Gemini API-ключ в настройках AI."
  case .invalidResponse: return "AI вернул ответ в неподдерживаемом формате. Попробуй ещё раз."
  case .requestFailed(let message): return message
  case .serviceUnavailable: return "Сервис AI временно недоступен. Попробуй позже."
  }
 }
}
protocol AIGenerationProvider {
 var identifier: String { get }
 func generateVocabulary(for request: AIGenerationRequest) async throws -> [AIGeneratedWord]
}
