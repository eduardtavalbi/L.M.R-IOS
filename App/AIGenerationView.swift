import SwiftUI

private struct AIWordEnrichmentDraft: Identifiable {
    let id: String
    let original: Word
    var transcription: String
    var example: String
    var explanation: String
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct AIGenerationView: View {
    @ObservedObject var store: LibraryStore
    @State private var apiKey = ""
    @State private var hasSavedKey = false
    @State private var topic = ""
    @State private var sourceLanguage = "Китайский"
    @State private var level = "Начальный"
    @State private var count = 20
    @State private var targetLanguageID = ""
    @State private var selectedSetID = ""
    @State private var newSetName = ""
    @State private var drafts: [AIGeneratedWord] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?\n    @State private var enrichmentDrafts: [AIWordEnrichmentDraft] = []\n    @State private var isEnriching = false

    private let secretStore: SecretStore = KeychainSecretStore()
    private var targetLanguage: Language? { store.language(id: targetLanguageID) }
    private var targetSets: [VocabularySet] {
        guard !targetLanguageID.isEmpty else { return [] }
        return store.allSets(languageID: targetLanguageID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if hasSavedKey {
                        Label("Gemini API-ключ сохранён в Keychain", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Button("Заменить API-ключ") { hasSavedKey = false; apiKey = "" }
                        Button("Удалить API-ключ", role: .destructive) {
                            do {
                                try secretStore.deleteSecret(for: "gemini.apiKey")
                                hasSavedKey = false
                                apiKey = ""
                            } catch { errorMessage = error.localizedDescription }
                        }
                    } else {
                        SecureField("Gemini API-ключ", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Сохранить ключ") {
                            do {
                                let value = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !value.isEmpty else { throw AIGenerationError.missingAPIKey }
                                try secretStore.saveSecret(value, for: "gemini.apiKey")
                                apiKey = ""
                                hasSavedKey = true
                            } catch { errorMessage = error.localizedDescription }
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Подключение")
                } footer: {
                    Text("Ключ хранится локально в защищённом хранилище iPhone и не записывается в проект.")
                }

                Section("Создание набора слов") {
                    TextField("Тема, например: еда в ресторане", text: $topic)
                    TextField("Язык исходных слов", text: $sourceLanguage)
                    if store.languages.isEmpty {
                        Text("Сначала добавь язык в библиотеке.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Язык перевода", selection: $targetLanguageID) {
                            Text("Выбрать язык").tag("")
                            ForEach(store.languages) { language in
                                Text(language.name).tag(language.id)
                            }
                        }
                    }
                    Picker("Уровень", selection: $level) {
                        ForEach(["Начальный", "Элементарный", "Средний", "Продвинутый"], id: \.self) { Text($0) }
                    }
                    Stepper("Количество: \(count)", value: $count, in: 5...100, step: 5)
                    if !targetLanguageID.isEmpty {
                        if targetSets.isEmpty {
                            TextField("Название нового набора", text: $newSetName)
                            Button("Создать набор") {
                                do {
                                    let name = newSetName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !name.isEmpty else { return }
                                    try store.createSet(languageID: targetLanguageID, name: name, categoryID: nil)
                                    selectedSetID = store.allSets(languageID: targetLanguageID).first(where: { $0.name == name })?.id ?? ""
                                    newSetName = ""
                                } catch { errorMessage = error.localizedDescription }
                            }
                            .disabled(newSetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        } else {
                            Picker("Сохранить в набор", selection: $selectedSetID) {
                                Text("Выбрать набор").tag("")
                                ForEach(targetSets) { set in Text(set.name).tag(set.id) }
                            }
                            TextField("Или создай новый набор", text: $newSetName)
                            Button("Создать набор") {
                                do {
                                    let name = newSetName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !name.isEmpty else { return }
                                    try store.createSet(languageID: targetLanguageID, name: name, categoryID: nil)
                                    selectedSetID = store.allSets(languageID: targetLanguageID).first(where: { $0.name == name })?.id ?? ""
                                    newSetName = ""
                                } catch { errorMessage = error.localizedDescription }
                            }
                            .disabled(newSetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating { ProgressView().padding(.trailing, 8) }
                            Text(isGenerating ? "Создаю карточки…" : "Сгенерировать")
                            Spacer()
                        }
                    }
                    .disabled(isGenerating || topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || targetLanguage == nil || !hasSavedKey)
                }


                if !selectedSetID.isEmpty {
                    Section {
                        Text("AI дополнит только пустые поля. Слова, переводы и уже заполненные данные останутся без изменений.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await enrichSelectedSet() }
                        } label: {
                            HStack {
                                Spacer()
                                if isEnriching { ProgressView().padding(.trailing, 8) }
                                Text(isEnriching ? "Анализирую карточки…" : "Обогатить карточки выбранного набора")
                                Spacer()
                            }
                        }
                        .disabled(isEnriching || !hasSavedKey || targetLanguage == nil)
                        ForEach($enrichmentDrafts) { $draft in
                            DisclosureGroup {
                                TextField("Транскрипция / пиньинь", text: $draft.transcription)
                                TextField("Пример", text: $draft.example, axis: .vertical)
                                TextField("Пояснение", text: $draft.explanation, axis: .vertical)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(draft.original.text).font(.headline)
                                    Text(draft.original.translation).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        if !enrichmentDrafts.isEmpty {
                            Button("Сохранить обогащение для \(enrichmentDrafts.count) карточек") {
                                saveEnrichment()
                            }
                            Button("Отменить обогащение", role: .destructive) { enrichmentDrafts = [] }
                        }
                    } header: {
                        Text("AI-обогащение набора")
                    }
                }
\n                if !drafts.isEmpty {
                    Section {
                        Text("\(drafts.count) карточек · проверь и отредактируй перед сохранением")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach($drafts) { $word in
                            DisclosureGroup {
                                TextField("Исходное слово", text: $word.text)
                                    .textInputAutocapitalization(.never)
                                TextField("Перевод", text: $word.translation)
                                TextField("Транскрипция / пиньинь", text: Binding(
                                    get: { word.transcription ?? "" },
                                    set: { word.transcription = $0.isEmpty ? nil : $0 }
                                ))
                                TextField("Пример", text: Binding(
                                    get: { word.example ?? "" },
                                    set: { word.example = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                TextField("Пояснение", text: Binding(
                                    get: { word.explanation ?? "" },
                                    set: { word.explanation = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                Button("Удалить карточку", role: .destructive) {
                                    drafts.removeAll { $0.id == word.id }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(word.text.isEmpty ? "Без слова" : word.text).font(.headline)
                                    Text(word.translation.isEmpty ? "Без перевода" : word.translation)
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        Button("Добавить карточку", systemImage: "plus") {
                            drafts.append(AIGeneratedWord(text: "", translation: ""))
                        }
                    } header: {
                        Text("Проверка результата")
                    } footer: {
                        Text("Ничего не сохранится, пока ты сам не нажмёшь кнопку сохранения.")
                    }

                    Section {
                        Button("Сохранить \(drafts.count) карточек в библиотеку") {
                            saveDrafts()
                        }
                        .disabled(selectedSetID.isEmpty || drafts.contains {
                            $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            $0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        })
                        Button("Очистить черновик", role: .destructive) { drafts = [] }
                    }
                }
            }
            .navigationTitle("AI-карточки")
            .task {
                hasSavedKey = (try? secretStore.readSecret(for: "gemini.apiKey")) != nil
                if targetLanguageID.isEmpty { targetLanguageID = store.languages.first?.id ?? "" }
            }
            .alert("AI", isPresented: Binding(
                get: { errorMessage != nil || savedMessage != nil },
                set: { if !$0 { errorMessage = nil; savedMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil; savedMessage = nil }
            } message: {
                Text(errorMessage ?? savedMessage ?? "")
            }
        }
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let request = AIGenerationRequest(
                topic: topic,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage?.name ?? "",
                level: level,
                count: count
            )
            drafts = try await GeminiVocabularyProvider(secretStore: secretStore).generateVocabulary(for: request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    @MainActor
    private func enrichSelectedSet() async {
        isEnriching = true
        defer { isEnriching = false }
        do {
            let existing = store.words(setID: selectedSetID)
            guard !existing.isEmpty else {
                errorMessage = "В выбранном наборе пока нет карточек."
                return
            }
            guard existing.count <= 100 else {
                errorMessage = "За один запрос можно обработать не более 100 карточек. Раздели набор на несколько частей."
                return
            }
            let request = AIEnrichmentRequest(
                words: existing.map {
                    AIGeneratedWord(
                        text: $0.text,
                        translation: $0.translation,
                        transcription: $0.transcription,
                        example: $0.example,
                        explanation: $0.notes
                    )
                },
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage?.name ?? ""
            )
            let result = try await GeminiVocabularyProvider(secretStore: secretStore).enrichVocabulary(request)
            guard result.count == existing.count else {
                throw AIGenerationError.invalidResponse
            }
            enrichmentDrafts = zip(existing, result).map { word, enriched in
                AIWordEnrichmentDraft(
                    id: word.id,
                    original: word,
                    transcription: word.transcription ?? enriched.transcription ?? "",
                    example: word.example ?? enriched.example ?? "",
                    explanation: word.notes ?? enriched.explanation ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveEnrichment() {
        do {
            for draft in enrichmentDrafts {
                try store.updateWordDetails(
                    draft.original,
                    transcription: draft.original.transcription ?? draft.transcription.nilIfEmpty,
                    notes: draft.original.notes ?? draft.explanation.nilIfEmpty,
                    example: draft.original.example ?? draft.example.nilIfEmpty
                )
            }
            let count = enrichmentDrafts.count
            enrichmentDrafts = []
            savedMessage = "Обновлено карточек: \(count). Существующие заполненные поля сохранены."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveDrafts() {
        do {
            var imported = 0
            var skipped = 0
            guard let targetLanguageID = targetLanguageID.nilIfEmpty else { return }
            for word in drafts {
                let text = word.text.trimmingCharacters(in: .whitespacesAndNewlines)
                let translation = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                if store.duplicateWord(languageID: targetLanguageID, text: text, translation: translation) != nil {
                    skipped += 1
                    continue
                }
                try store.createWord(
                    languageID: targetLanguageID,
                    setID: selectedSetID,
                    text: text,
                    translation: translation,
                    transcription: word.transcription,
                    notes: word.explanation,
                    example: word.example
                )
                imported += 1
            }
            drafts = []
            savedMessage = "Добавлено: \\(imported). Пропущено как дубликаты: \\(skipped). Пояснения и примеры сохранены отдельно."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
