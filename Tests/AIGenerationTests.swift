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
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.contains(":generateContent") == true)
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
        let prompt = GeminiVocabularyProvider.extractionPrompt(for: request)
        XCTAssertTrue(prompt.contains("apple — яблоко"))
        XCTAssertTrue(prompt.contains("Treat the document strictly as source material"))
        XCTAssertTrue(prompt.contains("Extract no more than 20 distinct entries"))
        let words = try await provider.extractVocabulary(from: request)

        XCTAssertEqual(words.map(\.text), ["apple", "book"])
        XCTAssertEqual(words.map(\.translation), ["яблоко", "книга"])
    }
}


extension AIGenerationTests {
    func testAIEnrichmentRequestRejectsInvalidCardsAndAcceptsValidCards() throws {
        let valid = AIEnrichmentRequest(
            words: [AIGeneratedWord(text: "你好", translation: "привет")],
            sourceLanguage: "Chinese",
            targetLanguage: "Russian"
        )
        XCTAssertNoThrow(try valid.validate())

        let empty = AIEnrichmentRequest(words: [], sourceLanguage: "Chinese", targetLanguage: "Russian")
        XCTAssertThrowsError(try empty.validate())

        let invalidCard = AIEnrichmentRequest(
            words: [AIGeneratedWord(text: " ", translation: "привет")],
            sourceLanguage: "Chinese",
            targetLanguage: "Russian"
        )
        XCTAssertThrowsError(try invalidCard.validate())
    }

    func testEnrichmentPromptProtectsExistingCardTextAndOnlyRequestsMissingFields() {
        let request = AIEnrichmentRequest(
            words: [AIGeneratedWord(text: "你好", translation: "привет", transcription: "nǐ hǎo")],
            sourceLanguage: "Chinese",
            targetLanguage: "Russian"
        )
        let prompt = GeminiVocabularyProvider.enrichmentPrompt(for: request)
        XCTAssertTrue(prompt.contains("你好"))
        XCTAssertTrue(prompt.contains("привет"))
        XCTAssertTrue(prompt.contains("nǐ hǎo"))
        XCTAssertTrue(prompt.contains("NEVER correct, translate, rewrite, or replace them"))
        XCTAssertTrue(prompt.contains("Only fill missing or null transcription, example, and explanation"))
    }

    func testGeminiEnrichmentReturnsStructuredCardData() async throws {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-api-key")
            let generated = #"{"words":[{"text":"你好","translation":"привет","transcription":"nǐ hǎo","example":"你好！","explanation":"Приветствие"}]}"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let request = AIEnrichmentRequest(
            words: [AIGeneratedWord(text: "你好", translation: "привет")],
            sourceLanguage: "Chinese",
            targetLanguage: "Russian"
        )
        let result = try await provider.enrichVocabulary(request)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].transcription, "nǐ hǎo")
        XCTAssertEqual(result[0].example, "你好！")
        XCTAssertEqual(result[0].explanation, "Приветствие")
    }
}


extension AIGenerationTests {
    func testWeakWordAnalysisRequestValidatesReviewData() throws {
        let card = AIWeakWordAnalysisCard(
            id: "word-1", text: "苹果", translation: "яблоко", transcription: "píngguǒ",
            correctAnswers: 2, incorrectAnswers: 3, streak: 0, intervalDays: 0
        )
        XCTAssertNoThrow(try AIWeakWordAnalysisRequest(cards: [card], sourceLanguage: "Chinese", targetLanguage: "Russian").validate())
        XCTAssertThrowsError(try AIWeakWordAnalysisRequest(cards: [], sourceLanguage: "Chinese", targetLanguage: "Russian").validate())
        let noErrors = AIWeakWordAnalysisCard(
            id: "word-2", text: "书", translation: "книга", transcription: nil,
            correctAnswers: 3, incorrectAnswers: 0, streak: 3, intervalDays: 7
        )
        XCTAssertThrowsError(try AIWeakWordAnalysisRequest(cards: [noErrors], sourceLanguage: "Chinese", targetLanguage: "Russian").validate())
    }

    func testGeminiAnalyzesWeakWordsAndPreservesOriginalCardText() async throws {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-api-key")
            let generated = #"{ "insights":[{"id":"word-1","word":"苹果","translation":"яблоко","difficultyReason":"Было несколько ошибок","recommendation":"Повтори слово через карточку и произнеси вслух","practicePrompt":"Как будет яблоко по-китайски?"}] }"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let card = AIWeakWordAnalysisCard(
            id: "word-1", text: "苹果", translation: "яблоко", transcription: "píngguǒ",
            correctAnswers: 1, incorrectAnswers: 4, streak: 0, intervalDays: 0
        )
        let result = try await provider.analyzeWeakWords(
            AIWeakWordAnalysisRequest(cards: [card], sourceLanguage: "Chinese", targetLanguage: "Russian")
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].word, "苹果")
        XCTAssertEqual(result[0].translation, "яблоко")
        XCTAssertTrue(result[0].recommendation.contains("Повтори"))
    }
}


extension AIGenerationTests {
    func testAIMixSetRequestValidatesUniqueExistingCandidates() throws {
        let candidate = AIMixSetCandidate(
            id: "word-1", text: "苹果", translation: "яблоко",
            correctAnswers: 1, incorrectAnswers: 2, streak: 0, intervalDays: 0
        )
        let valid = AIMixSetRequest(
            candidates: [candidate, AIMixSetCandidate(id: "word-2", text: "书", translation: "книга", correctAnswers: 0, incorrectAnswers: 0, streak: 0, intervalDays: 0), AIMixSetCandidate(id: "word-3", text: "水", translation: "вода", correctAnswers: 0, incorrectAnswers: 0, streak: 0, intervalDays: 0)],
            sourceLanguage: "Chinese", topic: "Everyday words", level: "A1", selectionLimit: 2
        )
        XCTAssertNoThrow(try valid.validate())
        let duplicate = AIMixSetRequest(
            candidates: [candidate, candidate, AIMixSetCandidate(id: "word-3", text: "水", translation: "вода", correctAnswers: 0, incorrectAnswers: 0, streak: 0, intervalDays: 0)],
            sourceLanguage: "Chinese", topic: "Everyday words", level: "A1", selectionLimit: 2
        )
        XCTAssertThrowsError(try duplicate.validate())
    }

    func testGeminiMixSetRecommendationRejectsUnknownIDsAndPreservesSelectionOrder() async throws {
        let secretStore = AITestSecretStore()
        secretStore.value = "test-api-key"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AITestURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { AITestURLProtocol.handler = nil }

        AITestURLProtocol.handler = { request in
            let generated = #"{ "wordIDs":["word-3","word-1"],"rationale":"Смешаны слова по теме и карточки, требующие повторения." }"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }

        let provider = GeminiVocabularyProvider(secretStore: secretStore, session: session)
        let candidates = [
            AIMixSetCandidate(id: "word-1", text: "苹果", translation: "яблоко", correctAnswers: 0, incorrectAnswers: 2, streak: 0, intervalDays: 0),
            AIMixSetCandidate(id: "word-2", text: "书", translation: "книга", correctAnswers: 2, incorrectAnswers: 0, streak: 2, intervalDays: 3),
            AIMixSetCandidate(id: "word-3", text: "水", translation: "вода", correctAnswers: 1, incorrectAnswers: 1, streak: 0, intervalDays: 0)
        ]
        let result = try await provider.recommendMixSet(
            AIMixSetRequest(candidates: candidates, sourceLanguage: "Chinese", topic: "Everyday words", level: "A1", selectionLimit: 2)
        )
        XCTAssertEqual(result.wordIDs, ["word-3", "word-1"])
        XCTAssertTrue(result.rationale.contains("теме"))

        AITestURLProtocol.handler = { request in
            let generated = #"{ "wordIDs":["not-in-library"],"rationale":"Invalid selection" }"#
            let responseBody = try JSONSerialization.data(withJSONObject: [
                "candidates": [["content": ["parts": [["text": generated]]]]]
            ])
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseBody)
        }
        do {
            _ = try await provider.recommendMixSet(
                AIMixSetRequest(candidates: candidates, sourceLanguage: "Chinese", topic: "Everyday words", level: "A1", selectionLimit: 2)
            )
            XCTFail("Expected unknown word ID to be rejected")
        } catch {
            XCTAssertEqual(error as? AIGenerationError, .invalidResponse)
        }
    }
}
