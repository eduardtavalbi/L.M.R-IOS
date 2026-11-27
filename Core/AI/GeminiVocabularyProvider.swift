import Foundation
final class GeminiVocabularyProvider: AIGenerationProvider {
 let identifier = "gemini"
 private let secretStore: SecretStore; private let session: URLSession; private let model: String
 init(secretStore: SecretStore = KeychainSecretStore(), session: URLSession = .shared, model: String = "gemini-2.5-flash") {
  self.secretStore=secretStore; self.session=session; self.model=model
 }
 func generateVocabulary(for request: AIGenerationRequest) async throws -> [AIGeneratedWord] {
  try request.validate()
  guard let apiKey = try secretStore.readSecret(for: "gemini.apiKey"),
   !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AIGenerationError.missingAPIKey }
  let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
  var urlRequest = URLRequest(url: endpoint); urlRequest.httpMethod = "POST"; urlRequest.timeoutInterval = 90
  urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
  urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  let prompt = """
  Create exactly \(request.count) useful vocabulary cards.
  Topic: \(request.topic)
  Source language (word): \(request.sourceLanguage)
  Target language (translation): \(request.targetLanguage)
  Learner level: \(request.level)
  Return only JSON: {"words":[{"text":"...","translation":"...","transcription":"...","example":"...","explanation":"..."}]}
  Every text and translation must be non-empty. Use null for unavailable optional fields. Avoid duplicates.
  """
  let body: [String: Any] = ["contents":[["parts":[["text":prompt]]]],
   "generationConfig":["responseMimeType":"application/json","temperature":0.4,"maxOutputTokens":max(1024,request.count*180)]]
  urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
  let (data,response) = try await session.data(for: urlRequest)
  guard let http = response as? HTTPURLResponse else { throw AIGenerationError.invalidResponse }
  guard (200..<300).contains(http.statusCode) else {
   if http.statusCode == 429 || http.statusCode >= 500 { throw AIGenerationError.serviceUnavailable }
   throw AIGenerationError.requestFailed("Gemini вернул ошибку HTTP \(http.statusCode). Проверь API-ключ и доступ к модели.")
  }
  guard let root = try JSONSerialization.jsonObject(with: data) as? [String:Any],
   let candidates = root["candidates"] as? [[String:Any]],
   let content = candidates.first?["content"] as? [String:Any],
   let parts = content["parts"] as? [[String:Any]],
   let generatedText = parts.compactMap({ $0["text"] as? String }).first else { throw AIGenerationError.invalidResponse }
  let clean = Self.removeMarkdownFence(from: generatedText)
  guard let json = clean.data(using: .utf8), let payload = try? JSONDecoder().decode(GeneratedPayload.self, from: json) else {
   throw AIGenerationError.invalidResponse
  }
  let words = payload.words.filter { !$0.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && !$0.translation.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty }
  guard !words.isEmpty else { throw AIGenerationError.invalidResponse }; return words
 }
 static func removeMarkdownFence(from text: String) -> String {
  let trimmed=text.trimmingCharacters(in:.whitespacesAndNewlines)
  let fence=String(repeating:Character(UnicodeScalar(96)!),count:3)
  guard trimmed.hasPrefix(fence) else { return trimmed }
  let lines=trimmed.components(separatedBy:.newlines)
  guard lines.count >= 3, lines.last?.trimmingCharacters(in:.whitespaces).hasPrefix(fence) == true else { return trimmed }
  return lines.dropFirst().dropLast().joined(separator:"\n").trimmingCharacters(in:.whitespacesAndNewlines)
 }
 private struct GeneratedPayload: Decodable { let words: [AIGeneratedWord] }
}
