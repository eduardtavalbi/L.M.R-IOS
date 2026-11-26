import Foundation

enum PairsCardSide: String {
    case prompt
    case answer
}

struct PairsCard: Identifiable, Equatable {
    let id: String
    let wordID: String
    let side: PairsCardSide
    let text: String
}

enum PairsGameEngine {
    static func makeCards(from words: [Word], pairCount: Int = 6) -> [PairsCard] {
        guard pairCount >= 2 else { return [] }

        var seen = Set<String>()
        let eligible = words.filter { word in
            let hasContent = !word.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasContent && seen.insert(word.id).inserted
        }

        let selected = Array(eligible.shuffled().prefix(pairCount))
        guard selected.count >= 2 else { return [] }

        return selected.flatMap { word in
            [
                PairsCard(id: "\(word.id)-prompt", wordID: word.id, side: .prompt, text: word.text),
                PairsCard(id: "\(word.id)-answer", wordID: word.id, side: .answer, text: word.translation)
            ]
        }.shuffled()
    }

    static func isMatch(_ first: PairsCard, _ second: PairsCard) -> Bool {
        first.wordID == second.wordID && first.side != second.side
    }
}
