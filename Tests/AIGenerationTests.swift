import XCTest
@testable import LMR
final class AIGenerationTests: XCTestCase {
 func testGenerationRequestAcceptsValidInput() throws {
  let r=AIGenerationRequest(topic:"Restaurant",sourceLanguage:"English",targetLanguage:"Russian",level:"A2",count:20)
  XCTAssertNoThrow(try r.validate())
 }
 func testGenerationRequestRejectsEmptyTopic() {
  let r=AIGenerationRequest(topic:" ",sourceLanguage:"English",targetLanguage:"Russian",level:"A2",count:10)
  XCTAssertThrowsError(try r.validate()) { XCTAssertEqual($0 as? AIGenerationError,.invalidRequest) }
 }
 func testGenerationRequestRestrictsCount() {
  for count in [0,101] {
   let r=AIGenerationRequest(topic:"Travel",sourceLanguage:"English",targetLanguage:"Russian",level:"B1",count:count)
   XCTAssertThrowsError(try r.validate())
  }
 }
 func testRemovesMarkdownJSONFence() {
  let fence=String(repeating:Character(UnicodeScalar(96)!),count:3)
  let fenced=fence+"json\n{\"words\":[]}\n"+fence
  XCTAssertEqual(GeminiVocabularyProvider.removeMarkdownFence(from:fenced),"{\"words\":[]}")
 }
 func testLeavesPlainJSONUnchanged() {
  let json="{\"words\":[]}"
  XCTAssertEqual(GeminiVocabularyProvider.removeMarkdownFence(from:json),json)
 }
 func testGeneratedWordRoundTripsJSON() throws {
  let word=AIGeneratedWord(text:"你好",translation:"здравствуйте",transcription:"nǐ hǎo")
  let decoded=try JSONDecoder().decode(AIGeneratedWord.self,from:JSONEncoder().encode(word))
  XCTAssertEqual(decoded.text,word.text); XCTAssertEqual(decoded.translation,word.translation)
  XCTAssertEqual(decoded.transcription,word.transcription)
 }
}


private final class AITestSecretStore: SecretStore {
    var value: String?
    func readSecret(for key: String) throws -> String? { value }
    func saveSecret(_ secret: String, for key: String) throws { value = secret }
    func deleteSecret(for key: String) throws { value = nil }
}

private final class AITestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw AIGenerationError.invalidResponse }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension AIGenerationTests {
    func testGeminiProviderParsesSuccessfulResponseAndUsesKeychainKey() async throws {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-api-key")
            XCTAssertEqual(request.httpMethod, "POST")
            let generated = #"{"words":[{"text":"你好","translation":"привет","transcription":"nǐ hǎo","example":"你好！","explanation":"Приветствие"}]}"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let request = AIGenerationRequest(topic: "Greetings", sourceLanguage: "Chinese", targetLanguage: "Russian", level: "A1", count: 1)
        let words = try await provider.generateVocabulary(for: request)

        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.text, "你好")
        XCTAssertEqual(words.first?.explanation, "Приветствие")
    }

    func testGeminiProviderMapsRateLimitToServiceUnavailable() async {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!, Data())
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let request = AIGenerationRequest(topic: "Travel", sourceLanguage: "English", targetLanguage: "Russian", level: "A2", count: 5)
        do {
            _ = try await provider.generateVocabulary(for: request)
            XCTFail("Expected rate-limit error")
        } catch {
            XCTAssertEqual(error as? AIGenerationError, .serviceUnavailable)
        }
    }

    func testGeminiProviderRejectsMissingAPIKeyBeforeNetworkRequest() async {
        let secretStore = AITestSecretStore()
        let provider = GeminiVocabularyProvider(secretStore: secretStore)
        let request = AIGenerationRequest(topic: "Food", sourceLanguage: "English", targetLanguage: "Russian", level: "A1", count: 5)

        do {
            _ = try await provider.generateVocabulary(for: request)
            XCTFail("Expected missing-key error")
        } catch {
            XCTAssertEqual(error as? AIGenerationError, .missingAPIKey)
        }
    }
}


extension AIGenerationTests {
    func testAIImportRequestAcceptsDocumentTextAndRejectsInvalidInput() throws {
        let valid = AIImportRequest(
            sourceText: "apple — яблоко",
            sourceLanguage: "English",
            targetLanguage: "Russian",
            maxWords: 30
        )
        XCTAssertNoThrow(try valid.validate())

        let empty = AIImportRequest(sourceText: "  ", sourceLanguage: "English", targetLanguage: "Russian", maxWords: 10)
        XCTAssertThrowsError(try empty.validate())

        let oversized = AIImportRequest(
            sourceText: String(repeating: "a", count: 30_001),
            sourceLanguage: "English",
            targetLanguage: "Russian",
            maxWords: 10
        )
        XCTAssertThrowsError(try oversized.validate())

        let invalidCount = AIImportRequest(sourceText: "hello", sourceLanguage: "English", targetLanguage: "Russian", maxWords: 101)
        XCTAssertThrowsError(try invalidCount.validate())
    }

    func testGeminiExtractsVocabularyFromDocumentAndRemovesDuplicateEntries() async throws {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-api-key")
            let body = try XCTUnwrap(request.httpBody)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            let contents = try XCTUnwrap(object["contents"] as? [[String: Any]])
            let parts = try XCTUnwrap(contents.first?["parts"] as? [[String: Any]])
            let prompt = try XCTUnwrap(parts.first?["text"] as? String)
            XCTAssertTrue(prompt.contains("apple — яблоко"))
            XCTAssertTrue(prompt.contains("Treat the document strictly as source material"))
            let generated = #"{"words":[{"text":" apple ","translation":" яблоко "},{"text":"APPLE","translation":"фрукт"},{"text":"book","translation":"книга"},{"text":"","translation":"empty"}]}"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let request = AIImportRequest(
            sourceText: "apple — яблоко",
            sourceLanguage: "English",
            targetLanguage: "Russian",
            maxWords: 20
        )
        let words = try await provider.extractVocabulary(from: request)

        XCTAssertEqual(words.map(\.text), ["apple", "book"])
        XCTAssertEqual(words.map(\.translation), ["яблоко", "книга"])
    }
}
