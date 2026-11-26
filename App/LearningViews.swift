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
                                Section(language.name) {
                                    ForEach(sets) { set in
                                        NavigationLink {
                                            LearningSessionView(store: store, set: set)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "rectangle.stack")
                                                    .font(.title3).foregroundStyle(.tint)
                                                    .frame(width: 38, height: 38)
                                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(set.name).font(.headline)
                                                    Text("\(store.words(setID: set.id).count) карточек")
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

private struct LearningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet
    @State private var words: [Word] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var knownCount = 0
    @State private var repeatCount = 0
    @State private var error: String?

    private var currentWord: Word? {
        words.indices.contains(currentIndex) ? words[currentIndex] : nil
    }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView("Набор пуст", systemImage: "rectangle.stack", description: Text("Добавь слова в этот набор, чтобы начать обучение."))
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
            if words.isEmpty { words = store.learningWords(setID: set.id) }
        }
        .alert("Не удалось сохранить прогресс", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func sessionView(word: Word) -> some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(currentIndex), total: Double(max(words.count, 1)))
                .tint(.accentColor)
            Spacer()
            VStack(spacing: 18) {
                Text(word.text)
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.65).lineLimit(4)
                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription).font(.title3).foregroundStyle(.secondary)
                }
                if isRevealed {
                    Divider().padding(.horizontal, 30)
                    Text(word.translation).font(.system(size: 28, weight: .medium, design: .rounded)).multilineTextAlignment(.center)
                    if let example = word.example, !example.isEmpty {
                        Text(example).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    if let notes = word.notes, !notes.isEmpty {
                        Text(notes).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                } else {
                    Text("Вспомни перевод").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.quaternary, lineWidth: 1) }
            Spacer()
            if isRevealed {
                HStack(spacing: 14) {
                    Button { submit(knew: false) } label: {
                        Label("Повторить", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity).padding(.vertical, 15)
                    }
                    .buttonStyle(.bordered).tint(.orange)
                    Button { submit(knew: true) } label: {
                        Label("Знаю", systemImage: "checkmark").frame(maxWidth: .infinity).padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button { withAnimation(.easeInOut(duration: 0.2)) { isRevealed = true } } label: {
                    Text("Показать перевод").frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
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

    private func submit(knew: Bool) {
        guard let word = currentWord else { return }
        do {
            try store.recordLearningAnswer(wordID: word.id, knewAnswer: knew)
            if knew { knownCount += 1 } else { repeatCount += 1 }
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
                isRevealed = false
            }
        } catch let caughtError { error = caughtError.localizedDescription }
    }
}
