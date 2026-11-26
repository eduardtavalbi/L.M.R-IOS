import SwiftUI

struct LearningView: View {
    @ObservedObject var store: LibraryStore

    var body: some View {
        NavigationStack {
            Group {
                if store.languages.isEmpty {
                    ContentUnavailableView("Пока нечего изучать", systemImage: "rectangle.stack", description: Text("Сначала добавь язык и карточки в библиотеку."))
                } else {
                    List {
                        ForEach(store.languages) { language in
                            let sets = store.allSets(languageID: language.id)
                            if !sets.isEmpty {
                                Section("Дополнительная практика") {
                                    NavigationLink {
                                        LearningSetPickerView(store: store, language: language, sets: sets, purpose: .weakWords)
                                    } label: {
                                        Label("Сложные слова", systemImage: "brain.head.profile")
                                    }
                                    NavigationLink {
                                        LearningSetPickerView(store: store, language: language, sets: sets, purpose: .mixSets)
                                    } label: {
                                        Label("Смешать наборы", systemImage: "square.stack.3d.up")
                                    }
                                }

                                Section("Игры · \(language.name)") {
                                    ForEach(sets) { set in
                                        NavigationLink {
                                            PairsGameView(store: store, set: set)
                                        } label: {
                                            HStack {
                                                Label("Pairs", systemImage: "square.grid.2x2")
                                                Spacer()
                                                Text(set.name).foregroundStyle(.secondary)
                                            }
                                        }
                                        NavigationLink {
                                            AudioChoiceGameView(store: store, set: set)
                                        } label: {
                                            HStack {
                                                Label("Audio choice", systemImage: "ear")
                                                Spacer()
                                                Text(set.name).foregroundStyle(.secondary)
                                            }
                                        }
                                        NavigationLink {
                                            SpeedGameView(store: store, set: set)
                                        } label: {
                                            HStack {
                                                Label("Speed", systemImage: "bolt")
                                                Spacer()
                                                Text(set.name).foregroundStyle(.secondary)
                                            }
                                        }
                                        NavigationLink {
                                            MissingWordGameView(store: store, set: set)
                                        } label: {
                                            HStack {
                                                Label("Missing", systemImage: "text.viewfinder")
                                                Spacer()
                                                Text(set.name).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            if !sets.isEmpty {
                                Section(language.name) {
                                    ForEach(sets) { set in
                                        NavigationLink {
                                            LearningModeSelectionView(store: store, set: set)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "rectangle.stack")
                                                    .font(.title3).foregroundStyle(.tint)
                                                    .frame(width: 38, height: 38)
                                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(set.name).font(.headline)
                                                    let total = store.words(setID: set.id).count
                                                    let due = store.dueWordCount(setID: set.id)
                                                    Text("\(due) к повторению · \(total) всего")
                                                        .font(.caption).foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.tint)
                                            }
                                            .padding(.vertical, 3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Обучение")
        }
    }
}

private struct LearningModeSelectionView: View {
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    var body: some View {
        List {
            Section {
                modeLink(.flashcards, description: "Вспоминай перевод и оценивай, насколько хорошо знаешь слово.")
                modeLink(.multipleChoice, description: "Выбирай правильный перевод среди вариантов.")
                modeLink(.typing, description: "Вводи перевод самостоятельно — без подсказок.")
            } header: {
                Text(set.name)
            }
        }
        .navigationTitle("Формат обучения")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modeLink(_ mode: StudyMode, description: String) -> some View {
        NavigationLink {
            LearningSessionView(store: store, set: set, mode: mode)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Label(mode.title, systemImage: mode.symbol)
                    .font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 5)
        }
    }
}

private struct LearningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet
    let mode: StudyMode

    @State private var words: [Word] = []
    @State private var allWords: [Word] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var typedAnswer = ""
    @State private var hasSubmitted = false
    @State private var lastAnswerCorrect = false
    @State private var knownCount = 0
    @State private var repeatCount = 0
    @State private var error: String?

    private var currentWord: Word? {
        words.indices.contains(currentIndex) ? words[currentIndex] : nil
    }

    private var choices: [String] {
        guard let word = currentWord else { return [] }
        return StudyModeEngine.multipleChoiceOptions(for: word, from: allWords)
    }

    private var activeMode: StudyMode {
        mode == .multipleChoice && choices.count < 2 ? .flashcards : mode
    }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView("Нет слов для повторения", systemImage: "rectangle.stack", description: Text("Новые слова и карточки с наступившим сроком повторения появятся здесь."))
            } else if currentIndex >= words.count {
                completionView
            } else if let word = currentWord {
                sessionView(word: word)
            }
        }
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !words.isEmpty && currentIndex < words.count {
                    Text("\(currentIndex + 1) / \(words.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            if words.isEmpty {
                allWords = store.words(setID: set.id)
                words = store.learningWords(setID: set.id)
            }
        }
        .alert("Не удалось сохранить прогресс", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func sessionView(word: Word) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentIndex), total: Double(max(words.count, 1)))
                .tint(.accentColor)

            if mode == .multipleChoice && activeMode == .flashcards {
                Label("Недостаточно вариантов", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
            VStack(spacing: 16) {
                Text(word.text)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.65).lineLimit(4)
                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription).font(.title3).foregroundStyle(.secondary)
                }
                if activeMode == .flashcards && isRevealed {
                    Divider().padding(.horizontal, 30)
                    Text(word.translation)
                        .font(.system(size: 27, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                    if let example = word.example, !example.isEmpty {
                        Text(example).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    if let notes = word.notes, !notes.isEmpty {
                        Text(notes).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                } else if activeMode == .flashcards {
                    Text("Вспомни перевод").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(26)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.quaternary, lineWidth: 1) }

            if activeMode == .multipleChoice {
                multipleChoiceContent(correctTranslation: word.translation)
            } else if activeMode == .typing {
                typingContent(correctTranslation: word.translation)
            } else if isRevealed {
                HStack(spacing: 14) {
                    Button { submit(knew: false) } label: {
                        Label("Повторить", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                    }
                    .buttonStyle(.bordered).tint(.orange)
                    Button { submit(knew: true) } label: {
                        Label("Знаю", systemImage: "checkmark")
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button { withAnimation(.easeInOut(duration: 0.2)) { isRevealed = true } } label: {
                    Text("Показать перевод").frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer(minLength: 8)
        }
        .padding()
    }

    @ViewBuilder
    private func multipleChoiceContent(correctTranslation: String) -> some View {
        if hasSubmitted {
            answerFeedback(correctTranslation: correctTranslation)
        } else {
            VStack(spacing: 10) {
                ForEach(Array(choices.enumerated()), id: \.offset) { _, choice in
                    Button {
                        submit(answer: choice, expected: correctTranslation)
                    } label: {
                        Text(choice).frame(maxWidth: .infinity).padding(.vertical, 13).contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func typingContent(correctTranslation: String) -> some View {
        VStack(spacing: 12) {
            if hasSubmitted {
                answerFeedback(correctTranslation: correctTranslation)
            } else {
                TextField("Введи перевод", text: $typedAnswer)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.done)
                    .onSubmit { submit(answer: typedAnswer, expected: correctTranslation) }
                    .textFieldStyle(.roundedBorder)
                Button("Проверить") { submit(answer: typedAnswer, expected: correctTranslation) }
                    .buttonStyle(.borderedProminent)
                    .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func answerFeedback(correctTranslation: String) -> some View {
        VStack(spacing: 10) {
            Label(lastAnswerCorrect ? "Верно" : "Пока не получилось",
                  systemImage: lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline).foregroundStyle(lastAnswerCorrect ? .green : .orange)
            if !lastAnswerCorrect {
                Text("Правильный ответ: \(correctTranslation)").font(.subheadline).multilineTextAlignment(.center)
            }
            Button("Дальше") { advance() }.buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 54)).foregroundStyle(.tint)
            Text("Сессия завершена").font(.title2.weight(.semibold))
            Text("Карточек просмотрено: \(words.count)").foregroundStyle(.secondary)
            HStack(spacing: 24) {
                Label("\(knownCount)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Label("\(repeatCount)", systemImage: "arrow.counterclockwise.circle.fill").foregroundStyle(.orange)
            }
            Button("Готово") { dismiss() }.buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func submit(answer: String, expected: String) {
        let isCorrect = StudyModeEngine.answersMatch(answer, expected: expected)
        do {
            try store.recordLearningAnswer(wordID: currentWord?.id ?? "", knewAnswer: isCorrect)
            if isCorrect { knownCount += 1 } else { repeatCount += 1 }
            lastAnswerCorrect = isCorrect
            hasSubmitted = true
        } catch let caughtError {
            error = caughtError.localizedDescription
        }
    }

    private func submit(knew: Bool) {
        guard let word = currentWord else { return }
        do {
            try store.recordLearningAnswer(wordID: word.id, knewAnswer: knew)
            if knew { knownCount += 1 } else { repeatCount += 1 }
            advance()
        } catch let caughtError {
            error = caughtError.localizedDescription
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
            isRevealed = false
            typedAnswer = ""
            hasSubmitted = false
        }
    }
}
