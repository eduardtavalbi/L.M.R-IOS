import AVFoundation
import SwiftUI

struct AudioChoiceGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    @State private var words: [Word] = []
    @State private var choices: [String] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var isCorrect = false
    @State private var score = 0
    @State private var synthesizer = AVSpeechSynthesizer()

    private var currentWord: Word? {
        words.indices.contains(currentIndex) ? words[currentIndex] : nil
    }

    private var languageCode: String? {
        store.language(id: set.languageID)?.code
    }

    private var isComplete: Bool {
        !words.isEmpty && currentIndex >= words.count
    }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView(
                    "Недостаточно слов",
                    systemImage: "ear",
                    description: Text("Для Audio choice нужны хотя бы два слова с разными переводами.")
                )
            } else if isComplete {
                completionView
            } else if let word = currentWord {
                questionView(word: word)
            }
        }
        .navigationTitle("Audio choice · \(set.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadGame)
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func questionView(word: Word) -> some View {
        VStack(spacing: 22) {
            HStack {
                Label("\(score) верно", systemImage: "checkmark.circle")
                Spacer()
                Text("\(currentIndex + 1) / \(words.count)")
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ProgressView(value: Double(currentIndex), total: Double(max(words.count, 1)))

            Spacer(minLength: 8)

            VStack(spacing: 18) {
                Image(systemName: "headphones")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Какое слово ты слышишь?")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Button(action: speakCurrentWord) {
                    Label("Прослушать слово", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Воспроизводит произношение слова на изучаемом языке")
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))

            VStack(spacing: 10) {
                ForEach(Array(choices.enumerated()), id: \.offset) { _, choice in
                    choiceButton(choice, correctTranslation: word.translation)
                }
            }

            if selectedAnswer != nil {
                VStack(spacing: 10) {
                    Label(isCorrect ? "Верно!" : "Правильный ответ: \(word.translation)",
                          systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(isCorrect ? .green : .orange)
                        .multilineTextAlignment(.center)
                    Button(currentIndex + 1 == words.count ? "Результат" : "Дальше") {
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer(minLength: 4)
            Text("Используется системный синтез речи. Доступность голосов зависит от iOS и установленных голосовых пакетов.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func choiceButton(_ choice: String, correctTranslation: String) -> some View {
        let isSelected = selectedAnswer == choice
        let isRight = StudyModeEngine.answersMatch(choice, expected: correctTranslation)

        return Button {
            guard selectedAnswer == nil else { return }
            isCorrect = isRight
            selectedAnswer = choice
            if isRight { score += 1 }
        } label: {
            HStack {
                Text(choice)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: isRight ? "checkmark.circle.fill" : "xmark.circle.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? (isRight ? .green : .orange) : .accentColor)
        .disabled(selectedAnswer != nil)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ear")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Игра завершена")
                .font(.title2.weight(.semibold))
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
        let eligible = store.words(setID: set.id)
            .filter(AudioChoiceGameEngine.canPlay)
        guard AudioChoiceGameEngine.canPlayGame(with: eligible) else { return }
        words = eligible.shuffled()
        prepareChoices()
    }

    private func prepareChoices() {
        guard let word = currentWord else {
            choices = []
            return
        }
        choices = AudioChoiceGameEngine.options(for: word, from: words)
    }

    private func speakCurrentWord() {
        guard let word = currentWord else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word.text)
        if let languageCode, !languageCode.isEmpty {
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    private func advance() {
        synthesizer.stopSpeaking(at: .immediate)
        selectedAnswer = nil
        currentIndex += 1
        prepareChoices()
    }

    private func restart() {
        synthesizer.stopSpeaking(at: .immediate)
        words = store.words(setID: set.id)
            .filter(AudioChoiceGameEngine.canPlay)
            .shuffled()
        if !AudioChoiceGameEngine.canPlayGame(with: words) {
            words = []
        }
        currentIndex = 0
        selectedAnswer = nil
        isCorrect = false
        score = 0
        prepareChoices()
    }
}
