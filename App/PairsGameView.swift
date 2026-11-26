import SwiftUI

struct PairsGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    @State private var cards: [PairsCard] = []
    @State private var selectedCardIDs: [String] = []
    @State private var mismatchedCardIDs = Set<String>()
    @State private var matchedWordIDs = Set<String>()
    @State private var moves = 0

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var pairCount: Int { cards.count / 2 }
    private var isComplete: Bool { pairCount > 0 && matchedWordIDs.count == pairCount }

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView(
                    "Недостаточно слов",
                    systemImage: "square.grid.2x2",
                    description: Text("Для игры нужно хотя бы два слова с переводами в этом наборе.")
                )
            } else if isComplete {
                completionView
            } else {
                gameBoard
            }
        }
        .navigationTitle("Pairs · \(set.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard cards.isEmpty else { return }
            cards = PairsGameEngine.makeCards(from: store.words(setID: set.id))
        }
    }

    private var gameBoard: some View {
        VStack(spacing: 18) {
            HStack {
                Label("\(matchedWordIDs.count) / \(pairCount)", systemImage: "checkmark.circle")
                Spacer()
                Label("\(moves) ходов", systemImage: "arrow.left.arrow.right")
            }
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)

            ProgressView(value: Double(matchedWordIDs.count), total: Double(max(pairCount, 1)))

            Text("Найди пары: слово и его перевод")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cards) { card in
                    cardButton(card)
                }
            }

            Spacer(minLength: 0)

            Text("Игра не меняет расписание интервального повторения.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func cardButton(_ card: PairsCard) -> some View {
        let isMatched = matchedWordIDs.contains(card.wordID)
        let isSelected = selectedCardIDs.contains(card.id)
        let isMismatch = mismatchedCardIDs.contains(card.id)

        return Button {
            select(card)
        } label: {
            Text(card.text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 82)
                .padding(.horizontal, 8)
                .background(
                    isMatched ? Color.green.opacity(0.13) :
                        (isMismatch ? Color.orange.opacity(0.16) :
                            (isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground))),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isMatched ? Color.green.opacity(0.55) :
                                (isMismatch ? Color.orange.opacity(0.7) :
                                    (isSelected ? Color.accentColor : Color.clear)),
                            lineWidth: 1.5
                        )
                }
                .foregroundStyle(isMatched ? .green : .primary)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .accessibilityLabel("\(card.side == .prompt ? "Слово" : "Перевод"): \(card.text)")
        .accessibilityAddTraits(isMatched ? .isSelected : [])
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 58))
                .foregroundStyle(.tint)
            Text("Все пары найдены!")
                .font(.title2.weight(.semibold))
            Text("Ходов: \(moves) · Пар: \(pairCount)")
                .foregroundStyle(.secondary)
            Button("Сыграть ещё раз", action: restart)
                .buttonStyle(.borderedProminent)
            Button("Готово") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func select(_ card: PairsCard) {
        guard !matchedWordIDs.contains(card.wordID),
              !selectedCardIDs.contains(card.id) else { return }

        if selectedCardIDs.count == 2 {
            selectedCardIDs.removeAll()
            mismatchedCardIDs.removeAll()
        }

        guard let firstID = selectedCardIDs.first,
              let first = cards.first(where: { $0.id == firstID }) else {
            selectedCardIDs = [card.id]
            return
        }

        moves += 1
        if PairsGameEngine.isMatch(first, card) {
            matchedWordIDs.insert(card.wordID)
            selectedCardIDs.removeAll()
            mismatchedCardIDs.removeAll()
        } else {
            selectedCardIDs = [first.id, card.id]
            mismatchedCardIDs = [first.id, card.id]
        }
    }

    private func restart() {
        let words = store.words(setID: set.id)
        cards = PairsGameEngine.makeCards(from: words)
        selectedCardIDs.removeAll()
        mismatchedCardIDs.removeAll()
        matchedWordIDs.removeAll()
        moves = 0
    }
}
