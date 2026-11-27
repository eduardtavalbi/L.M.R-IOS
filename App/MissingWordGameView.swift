import SwiftUI

struct MissingWordGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    @State private var words: [Word] = []
    @State private var index = 0
    @State private var answer = ""
    @State private var submitted = false
    @State private var wasCorrect = false
    @State private var score = 0

    private var currentWord: Word? { words.indices.contains(index) ? words[index] : nil }
    private var isComplete: Bool { !words.isEmpty && index >= words.count }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView(
                    "Нет подходящих примеров",
                    systemImage: "text.badge.plus",
                    description: Text("Для Missing добавь к словам примеры предложений, в которых встречается само изучаемое слово.")
                )
            } else if isComplete {
                resultView
            } else if let word = currentWord {
                questionView(word: word)
            }
        }
        .navigationTitle("Missing · \(set.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadGame)
    }

    private func questionView(word: Word) -> some View {
        VStack(spacing: 22) {
            HStack {
                Label("\(score) верно", systemImage: "checkmark.circle")
                Spacer()
                Text("\(index + 1) / \(words.count)").monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ProgressView(value: Double(index), total: Double(max(words.count, 1)))

            Spacer(minLength: 12)

            VStack(spacing: 18) {
                Text(word.translation)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(MissingWordGameEngine.sentenceWithMissingWord(for: word) ?? "")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .padding(.top, 6)

                Text("Восстанови пропущенное слово")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(26)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))

            if submitted {
                VStack(spacing: 12) {
                    Label(wasCorrect ? "Верно!" : "Правильный ответ: \(word.text)",
                          systemImage: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(wasCorrect ? .green : .orange)
                        .multilineTextAlignment(.center)
                    Button(index + 1 == words.count ? "Результат" : "Дальше", action: advance)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                TextField("Пропущенное слово…", text: $answer)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { check(word: word) }

                Button("Проверить") { check(word: word) }
                    .buttonStyle(.borderedProminent)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer(minLength: 8)
        }
        .padding()
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.viewfinder")
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text("Игра завершена").font(.title2.weight(.semibold))
            Text("Правильных ответов: \(score) из \(words.count)")
                .foregroundStyle(.secondary)
            Button("Сыграть ещё раз", action: restart)
                .buttonStyle(.borderedProminent)
            Button("Готово") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func loadGame() {
        guard words.isEmpty else { return }
        words = MissingWordGameEngine.eligibleWords(store.words(setID: set.id)).shuffled()
    }

    private func check(word: Word) {
        guard !submitted else { return }
        wasCorrect = MissingWordGameEngine.answersMatch(answer, expected: word.text)
        submitted = true
        if wasCorrect { score += 1 }
    }

    private func advance() {
        index += 1
        answer = ""
        submitted = false
        wasCorrect = false
    }

    private func restart() {
        words = MissingWordGameEngine.eligibleWords(store.words(setID: set.id)).shuffled()
        index = 0
        answer = ""
        submitted = false
        wasCorrect = false
        score = 0
    }
}
