import SwiftUI

struct SpeedGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    @State private var words: [Word] = []
    @State private var index = 0
    @State private var answer = ""
    @State private var timeRemaining = 60
    @State private var score = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var submitted = false
    @State private var wasCorrect = false
    @State private var correctCount = 0
    @State private var timer: Timer?

    private var currentWord: Word? { words.indices.contains(index) ? words[index] : nil }
    private var isFinished: Bool { timeRemaining <= 0 || index >= words.count }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView("Недостаточно карточек", systemImage: "bolt", description: Text("Добавь хотя бы одно слово с переводом в набор."))
            } else if isFinished {
                resultView
            } else if let word = currentWord {
                playView(word: word)
            }
        }
        .navigationTitle("Speed · \(set.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: start)
        .onDisappear { timer?.invalidate(); timer = nil }
    }

    private func playView(word: Word) -> some View {
        VStack(spacing: 18) {
            HStack {
                Label("\(timeRemaining) сек", systemImage: "timer")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(timeRemaining <= 10 ? .red : .primary)
                Spacer()
                Label("\(score)", systemImage: "bolt.fill")
                    .font(.title3.weight(.bold))
            }
            ProgressView(value: Double(timeRemaining), total: 60)
                .tint(timeRemaining <= 10 ? .red : .accentColor)
                .accessibilityLabel("Оставшееся время")
                .accessibilityValue("\(timeRemaining) секунд из 60")

            Text("Серия: \(streak) · Рекорд: \(bestStreak)")
                .font(.caption).foregroundStyle(.secondary)

            Spacer()
            VStack(spacing: 12) {
                Text(word.text)
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.65)
                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription).font(.title3).foregroundStyle(.secondary)
                }
                Text("Напиши перевод")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))

            if submitted {
                Label(wasCorrect ? "Верно! + очки" : "Ответ: \(word.translation)",
                      systemImage: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(wasCorrect ? .green : .orange)
                    .font(.headline)
                Button("Следующее слово", action: advance)
                    .buttonStyle(.borderedProminent)
            } else {
                TextField("Перевод…", text: $answer)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .submitLabel(.done).textFieldStyle(.roundedBorder)
                    .onSubmit { check(word: word) }
                Button("Проверить") { check(word: word) }
                    .buttonStyle(.borderedProminent)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Пропустить", action: advance)
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding()
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: "bolt.circle.fill").font(.largeTitle).foregroundStyle(.tint)
            Text("Время!").font(.title2.weight(.semibold))
            Text("Очки: \(score)").font(.title.weight(.bold))
            Text("Правильных: \(correctCount) · Максимальная серия: \(bestStreak)")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Играть снова", action: start)
                .buttonStyle(.borderedProminent)
            Button("Готово") { dismiss() }.buttonStyle(.bordered)
        }
        .padding()
    }

    private func start() {
        timer?.invalidate()
        words = SpeedGameEngine.eligibleWords(store.words(setID: set.id)).shuffled()
        index = 0; answer = ""; timeRemaining = 60; score = 0; streak = 0
        bestStreak = 0; submitted = false; wasCorrect = false; correctCount = 0
        guard !words.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 { timer?.invalidate(); timer = nil }
        }
    }

    private func check(word: Word) {
        guard !submitted else { return }
        let correct = SpeedGameEngine.answersMatch(answer, expected: word.translation)
        wasCorrect = correct; submitted = true
        if correct {
            streak += 1; bestStreak = max(bestStreak, streak); correctCount += 1
            score += SpeedGameEngine.points(forCorrectAnswer: streak)
        } else {
            streak = 0
        }
    }

    private func advance() {
        index += 1; answer = ""; submitted = false; wasCorrect = false
    }
}
