import SwiftUI

enum LearningExtraPurpose {
    case weakWords
    case mixSets

    var title: String {
        switch self {
        case .weakWords: return "Сложные слова"
        case .mixSets: return "Смешать наборы"
        }
    }

    var description: String {
        switch self {
        case .weakWords: return "Слова, в которых раньше допускались ошибки."
        case .mixSets: return "Одна сессия из нескольких выбранных наборов."
        }
    }
}

struct LearningSetPickerView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let sets: [VocabularySet]
    let purpose: LearningExtraPurpose
    @State private var selectedIDs = Set<String>()

    var body: some View {
        List {
            Section {
                ForEach(sets) { set in
                    Button {
                        if selectedIDs.contains(set.id) {
                            selectedIDs.remove(set.id)
                        } else {
                            selectedIDs.insert(set.id)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(set.name).foregroundStyle(.primary)
                                Text("\(store.words(setID: set.id).count) слов")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedIDs.contains(set.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            } else {
                                Image(systemName: "circle").foregroundStyle(.tertiary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text(purpose.description)
            }
        }
        .navigationTitle(purpose.title)
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                ExtraLearningModeView(
                    store: store,
                    sets: sets.filter { selectedIDs.contains($0.id) },
                    purpose: purpose
                )
            } label: {
                Text("Продолжить · \(selectedIDs.count)")
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIDs.isEmpty)
            .padding()
            .background(.bar)
        }
    }
}

struct AIMixSetPickerView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let sets: [VocabularySet]

    @State private var selectedIDs = Set<String>()
    @State private var topic = "Слабые слова и повторение"
    @State private var level = "Начальный"
    @State private var selectionLimit = 15
    @State private var recommendation: AIMixSetRecommendation?
    @State private var candidateWords: [Word] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var selectedSets: [VocabularySet] { sets.filter { selectedIDs.contains($0.id) } }

    var body: some View {
        List {
            Section("Наборы") {
                ForEach(sets) { set in
                    Button {
                        if selectedIDs.contains(set.id) { selectedIDs.remove(set.id) }
                        else { selectedIDs.insert(set.id) }
                        recommendation = nil
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(set.name).foregroundStyle(.primary)
                                Text("\\(store.words(setID: set.id).count) слов").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedIDs.contains(set.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIDs.contains(set.id) ? .tint : .tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Параметры AI-тренировки") {
                TextField("Тема или цель", text: $topic)
                Picker("Уровень", selection: $level) {
                    ForEach(["Начальный", "Элементарный", "Средний", "Продвинутый"], id: \\.self) { Text($0) }
                }
                Stepper("Карточек в тренировке: \\(selectionLimit)", value: $selectionLimit, in: 3...30)
                Text("AI выберет карточки только из отмеченных наборов. Новые слова не создаются, а история SRS сохраняется.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button {
                    Task { await buildRecommendation() }
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating { ProgressView().padding(.trailing, 8) }
                        Text(isGenerating ? "Подбираю карточки…" : "Составить AI-тренировку")
                        Spacer()
                    }
                }
                .disabled(isGenerating || selectedIDs.isEmpty || topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let recommendation {
                Section("Предложенная тренировка · \\(recommendation.wordIDs.count) слов") {
                    Text(recommendation.rationale).font(.subheadline).foregroundStyle(.secondary)
                    ForEach(recommendation.wordIDs, id: \\.self) { id in
                        if let word = candidateWords.first(where: { $0.id == id }) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(word.text).font(.headline)
                                Text(word.translation).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    NavigationLink {
                        AIMixSetModeView(
                            store: store,
                            sets: selectedSets,
                            words: candidateWords,
                            selectedWordIDs: recommendation.wordIDs
                        )
                    } label: {
                        Label("Начать тренировку", systemImage: "play.fill")
                    }
                }
            }
        }
        .navigationTitle("AI Mix Sets")
        .alert("Не удалось составить тренировку", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    @MainActor
    private func buildRecommendation() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let words = store.words(setIDs: Array(selectedIDs))
            guard (3...100).contains(words.count) else {
                throw AIGenerationError.requestFailed("Выбери наборы, в которых суммарно от 3 до 100 уникальных карточек.")
            }
            candidateWords = words
            let cards = words.map { word -> AIMixSetCandidate in
                let progress = store.learningProgress(wordID: word.id)
                return AIMixSetCandidate(
                    id: word.id,
                    text: word.text,
                    translation: word.translation,
                    correctAnswers: progress?.correctAnswers ?? 0,
                    incorrectAnswers: progress?.incorrectAnswers ?? 0,
                    streak: progress?.streak ?? 0,
                    intervalDays: progress?.intervalDays ?? 0
                )
            }
            let request = AIMixSetRequest(
                candidates: cards,
                sourceLanguage: language.name,
                topic: topic.trimmingCharacters(in: .whitespacesAndNewlines),
                level: level,
                selectionLimit: min(selectionLimit, words.count)
            )
            recommendation = try await GeminiVocabularyProvider().recommendMixSet(request)
        } catch {
            recommendation = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct AIMixSetModeView: View {
    @ObservedObject var store: LibraryStore
    let sets: [VocabularySet]
    let words: [Word]
    let selectedWordIDs: [String]

    var body: some View {
        List {
            Section {
                ForEach([StudyMode.flashcards, .multipleChoice, .typing], id: \\.self) { mode in
                    NavigationLink {
                        MultiSetLearningSessionView(
                            store: store,
                            sets: sets,
                            purpose: .mixSets,
                            mode: mode,
                            selectedWordIDs: selectedWordIDs
                        )
                    } label: {
                        Label(mode.title, systemImage: mode.symbol)
                    }
                }
            } footer: {
                Text("\\(selectedWordIDs.count) карточек, выбранных AI из твоей библиотеки.")
            }
        }
        .navigationTitle("Формат обучения")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExtraLearningModeView: View {
    @ObservedObject var store: LibraryStore
    let sets: [VocabularySet]
    let purpose: LearningExtraPurpose

    var body: some View {
        List {
            Section {
                ForEach([StudyMode.flashcards, .multipleChoice, .typing], id: \.self) { mode in
                    NavigationLink {
                        MultiSetLearningSessionView(store: store, sets: sets, purpose: purpose, mode: mode)
                    } label: {
                        Label(mode.title, systemImage: mode.symbol)
                    }
                }
            } header: {
                Text(sets.map(\.name).joined(separator: ", "))
            }
        }
        .navigationTitle("Формат обучения")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MultiSetLearningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let sets: [VocabularySet]
    let purpose: LearningExtraPurpose
    let mode: StudyMode

    @State private var words: [Word] = []
    @State private var allWords: [Word] = []
    @State private var index = 0
    @State private var revealed = false
    @State private var answer = ""
    @State private var submitted = false
    @State private var correct = false
    @State private var known = 0
    @State private var needsWork = 0
    @State private var error: String?

    private var current: Word? { words.indices.contains(index) ? words[index] : nil }
    private var title: String { purpose.title }
    private var choices: [String] {
        guard let current else { return [] }
        return StudyModeEngine.multipleChoiceOptions(for: current, from: allWords)
    }
    private var activeMode: StudyMode {
        mode == .multipleChoice && choices.count < 2 ? .flashcards : mode
    }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView(
                    purpose == .weakWords ? "Сложных слов пока нет" : "Нет карточек для повторения",
                    systemImage: "checkmark.seal",
                    description: Text(purpose == .weakWords
                        ? "Ошибки в выбранных наборах появятся здесь после обучения."
                        : "В выбранных наборах нет новых или готовых к повторению слов.")
                )
            } else if index >= words.count {
                completion
            } else if let current {
                card(current)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if index < words.count && !words.isEmpty {
                    Text("\(index + 1) / \(words.count)").font(.caption.monospacedDigit())
                }
            }
        }
        .onAppear {
            guard words.isEmpty else { return }
            let ids = sets.map(\.id)
            allWords = store.words(setIDs: ids)
            if let selectedWordIDs {
                let byID = Dictionary(uniqueKeysWithValues: allWords.map { ($0.id, $0) })
                words = selectedWordIDs.compactMap { byID[$0] }
            } else {
                words = purpose == .weakWords
                    ? store.weakWords(setIDs: ids)
                    : store.learningWords(setIDs: ids)
            }
        }
        .alert("Не удалось сохранить прогресс", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func card(_ word: Word) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(max(words.count, 1)))
            Spacer(minLength: 4)
            VStack(spacing: 14) {
                Text(word.text)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription).foregroundStyle(.secondary)
                    ChineseToneGuideView(transcription: transcription, languageCode: store.language(id: sets.first?.languageID ?? "")?.code)
                }
                PronunciationControlsView(word: word, languageCode: store.language(id: sets.first?.languageID ?? "")?.code)
                if activeMode == .flashcards && revealed {
                    Divider()
                    Text(word.translation).font(.title2.weight(.medium))
                    if let example = word.example, !example.isEmpty {
                        Text(example).foregroundStyle(.secondary)
                    }
                    if let notes = word.notes, !notes.isEmpty {
                        Text(notes).font(.footnote).foregroundStyle(.secondary)
                    }
                } else if activeMode == .flashcards {
                    Text("Вспомни перевод").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity).padding(26)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            if activeMode == .flashcards {
                if revealed {
                    HStack {
                        Button("Повторить") { record(false, word: word) }
                            .buttonStyle(.bordered).tint(.orange)
                        Button("Знаю") { record(true, word: word) }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button("Показать перевод") { revealed = true }
                        .buttonStyle(.borderedProminent)
                }
            } else if activeMode == .multipleChoice {
                if submitted {
                    feedback(word: word)
                } else {
                    ForEach(Array(choices.enumerated()), id: \.offset) { _, choice in
                        Button(choice) { check(choice, expected: word.translation, word: word) }
                            .buttonStyle(.bordered).frame(maxWidth: .infinity)
                    }
                }
            } else if submitted {
                feedback(word: word)
            } else {
                TextField("Введи перевод", text: $answer)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { check(answer, expected: word.translation, word: word) }
                Button("Проверить") { check(answer, expected: word.translation, word: word) }
                    .buttonStyle(.borderedProminent)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Spacer(minLength: 4)
        }
        .padding()
    }

    private func feedback(word: Word) -> some View {
        VStack(spacing: 10) {
            Label(correct ? "Верно" : "Правильный ответ: \(word.translation)",
                  systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? .green : .orange)
            Button("Дальше") { advance() }.buttonStyle(.borderedProminent)
        }
    }

    private var completion: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 52)).foregroundStyle(.tint)
            Text("Сессия завершена").font(.title2.weight(.semibold))
            Text("Карточек: \(words.count)").foregroundStyle(.secondary)
            HStack(spacing: 22) {
                Label("\(known)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Label("\(needsWork)", systemImage: "arrow.counterclockwise.circle.fill").foregroundStyle(.orange)
            }
            Button("Готово") { dismiss() }.buttonStyle(.borderedProminent)
        }.padding()
    }

    private func check(_ value: String, expected: String, word: Word) {
        let matches = StudyModeEngine.answersMatch(value, expected: expected)
        correct = matches
        submitted = true
        do {
            try store.recordLearningAnswer(wordID: word.id, knewAnswer: matches)
            if matches { known += 1 } else { needsWork += 1 }
        } catch { self.error = error.localizedDescription }
    }

    private func record(_ knew: Bool, word: Word) {
        do {
            try store.recordLearningAnswer(wordID: word.id, knewAnswer: knew)
            if knew { known += 1 } else { needsWork += 1 }
            advance()
        } catch let caughtError { error = caughtError.localizedDescription }
    }

    private func advance() {
        index += 1
        revealed = false
        answer = ""
        submitted = false
    }
}
