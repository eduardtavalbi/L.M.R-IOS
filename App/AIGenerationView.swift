import SwiftUI

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
    @State private var savedMessage: String?

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

                if !drafts.isEmpty {
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

    private func saveDrafts() {
        do {
            let rows = drafts.map { word in
                WordImportDraft(
                    text: word.text,
                    translation: word.translation,
                    transcription: word.transcription ?? "",
                    example: [word.example, word.explanation.map { "Пояснение: " + $0 }]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n\n"),
                    duplicateResolution: .skip
                )
            }
            let result = try store.importWords(rows, intoSet: selectedSetID)
            drafts = []
            savedMessage = "Добавлено: \(result.imported). Пропущено как дубликаты: \(result.skipped)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
