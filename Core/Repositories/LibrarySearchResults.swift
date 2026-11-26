import Foundation

struct WordSearchMatch: Identifiable {
    let word: Word
    let sets: [VocabularySet]
    var id: String { word.id }
}

struct LibrarySearchResults {
    let words: [WordSearchMatch]
    let sets: [VocabularySet]
    let categories: [Category]
    var isEmpty: Bool { words.isEmpty && sets.isEmpty && categories.isEmpty }
}
