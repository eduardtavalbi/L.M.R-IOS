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
