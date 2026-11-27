import SwiftUI

struct LibraryView: View {
    @ObservedObject var store: LibraryStore
    @State private var showingCreateLanguage = false
    @State private var searchText = ""

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if !normalizedSearchText.isEmpty {
                    LibrarySearchView(store: store, query: normalizedSearchText)
                } else if store.languages.isEmpty {
                    ContentUnavailableView {
                        Label("Библиотека пока пуста", systemImage: "books.vertical")
                    } description: {
                        Text("Добавь язык, создай наборы и собирай собственный словарь.")
                    } actions: {
                        Button("Добавить язык") { showingCreateLanguage = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(store.languages) { language in
                                NavigationLink {
                                    LanguageLibraryView(store: store, language: language)
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "character.book.closed")
                                            .font(.title2).foregroundStyle(.tint)
                                            .frame(width: 42, height: 42)
                                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(language.name).font(.headline)
                                            Text(language.code?.uppercased() ?? "Язык")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Text("Мои языки")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Библиотека")
            .searchable(text: $searchText, prompt: "Слово, перевод, набор или категория")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateLanguage = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Добавить язык")
                }
            }
            .sheet(isPresented: $showingCreateLanguage) { CreateLanguageSheet(store: store) }
            .alert("Ошибка", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) { store.lastError = nil }
            } message: {
                Text(store.lastError ?? "")
            }
        }
    }
}

private struct LibrarySearchView: View {
    @ObservedObject var store: LibraryStore
    let query: String

    private var results: LibrarySearchResults { store.search(query: query) }

    var body: some View {
        let results = results
        List {
            if results.isEmpty { ContentUnavailableView.search(text: query) }

            if !results.words.isEmpty {
                Section("Слова и переводы") {
                    ForEach(results.words) { match in
                        NavigationLink {
                            WordSearchDetailView(store: store, match: match)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(match.word.text).font(.headline)
                                Text(match.word.translation).font(.subheadline).foregroundStyle(.secondary)
                                Text(match.sets.isEmpty
                                     ? "Пока не входит ни в один набор"
                                     : match.sets.map(\.name).joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.tint).lineLimit(2)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }

            if !results.sets.isEmpty {
                Section("Наборы") {
                    ForEach(results.sets) { set in
                        if let language = store.language(id: set.languageID) {
                            NavigationLink {
                                VocabularySetView(store: store, language: language, set: set)
                            } label: {
                                Label(set.name, systemImage: "rectangle.stack")
                            }
                        }
                    }
                }
            }

            if !results.categories.isEmpty {
                Section("Категории") {
                    ForEach(results.categories) { category in
                        if let language = store.language(id: category.languageID) {
                            NavigationLink {
                                CategoryLibraryView(store: store, language: language, category: category)
                            } label: {
                                Label(category.name, systemImage: "folder")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct WordSearchDetailView: View {
    @ObservedObject var store: LibraryStore
    let match: WordSearchMatch

    var body: some View {
        List {
            Section("Карточка") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(match.word.text).font(.title2.weight(.semibold))
                    Text(match.word.translation).foregroundStyle(.secondary)
                    if let transcription = match.word.transcription, !transcription.isEmpty {
                        Text(transcription).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Встречается в наборах") {
                if match.sets.isEmpty {
                    ContentUnavailableView("Нет связанных наборов", systemImage: "rectangle.stack")
                } else {
                    ForEach(match.sets) { set in
                        if let language = store.language(id: set.languageID) {
                            NavigationLink {
                                VocabularySetView(store: store, language: language, set: set)
                            } label: {
                                Label(set.name, systemImage: "rectangle.stack")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Результат поиска")
    }
}

struct LanguageLibraryView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    @State private var showingCategory = false
    @State private var showingSet = false
    @State private var showingEditLanguage = false
    @State private var confirmingDeleteLanguage = false

    var body: some View {
        List {
            let categories = store.categories(languageID: language.id)
            let sets = store.sets(languageID: language.id)
            if !categories.isEmpty {
                Section("Категории") {
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryLibraryView(store: store, language: language, category: category)
                        } label: {
                            Label(category.name, systemImage: "folder")
                        }
                    }
                }
            }
            Section {
                if sets.isEmpty {
                    ContentUnavailableView("Нет наборов без категории", systemImage: "square.stack.3d.up")
                } else {
                    ForEach(sets) { set in
                        NavigationLink {
                            VocabularySetView(store: store, language: language, set: set)
                        } label: {
                            SetRow(store: store, set: set)
                        }
                    }
                }
            } header: {
                Text("Без категории")
            }
        }
        .navigationTitle(language.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Новая категория", systemImage: "folder.badge.plus") { showingCategory = true }
                    Button("Новый набор", systemImage: "plus") { showingSet = true }
                    Divider()
                    Button("Изменить язык", systemImage: "pencil") { showingEditLanguage = true }
                    Button("Удалить язык", systemImage: "trash", role: .destructive) { confirmingDeleteLanguage = true }
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Действия с языком")
                }
            }
        }
        .sheet(isPresented: $showingCategory) { CreateCategorySheet(store: store, language: language, parentID: nil) }
        .sheet(isPresented: $showingSet) { CreateSetSheet(store: store, language: language, categoryID: nil) }
        .sheet(isPresented: $showingEditLanguage) { EditLanguageSheet(store: store, language: language) }
        .confirmationDialog("Удалить язык «\(language.name)»?", isPresented: $confirmingDeleteLanguage, titleVisibility: .visible) {
            Button("Удалить язык и всё его содержимое", role: .destructive) {
                do { try store.deleteLanguage(language.id) } catch { store.lastError = error.localizedDescription }
            }
        } message: {
            Text("Будут удалены все категории, наборы, слова и прогресс этого языка. Это действие нельзя отменить.")
        }
    }
}

struct CategoryLibraryView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let category: Category
    @State private var showingCategory = false
    @State private var showingSet = false
    @State private var showingEditCategory = false
    @State private var confirmingDeleteCategory = false

    var body: some View {
        List {
            let children = store.categories(languageID: language.id, parentID: category.id)
            let sets = store.sets(languageID: language.id, categoryID: category.id)
            if !children.isEmpty {
                Section("Вложенные категории") {
                    ForEach(children) { child in
                        NavigationLink {
                            CategoryLibraryView(store: store, language: language, category: child)
                        } label: {
                            Label(child.name, systemImage: "folder")
                        }
                    }
                }
            }
            Section("Наборы") {
                if sets.isEmpty {
                    ContentUnavailableView("В этой категории пока нет наборов", systemImage: "square.stack.3d.up")
                } else {
                    ForEach(sets) { set in
                        NavigationLink {
                            VocabularySetView(store: store, language: language, set: set)
                        } label: {
                            SetRow(store: store, set: set)
                        }
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Вложенная категория", systemImage: "folder.badge.plus") { showingCategory = true }
                    Button("Новый набор", systemImage: "plus") { showingSet = true }
                    Divider()
                    Button("Изменить категорию", systemImage: "pencil") { showingEditCategory = true }
                    Button("Удалить категорию", systemImage: "trash", role: .destructive) { confirmingDeleteCategory = true }
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCategory) { CreateCategorySheet(store: store, language: language, parentID: category.id) }
        .sheet(isPresented: $showingSet) { CreateSetSheet(store: store, language: language, categoryID: category.id) }
        .sheet(isPresented: $showingEditCategory) { EditCategorySheet(store: store, category: category) }
        .confirmationDialog("Удалить категорию «\(category.name)»?", isPresented: $confirmingDeleteCategory, titleVisibility: .visible) {
            Button("Удалить категорию", role: .destructive) {
                do { try store.deleteCategory(category.id) } catch { store.lastError = error.localizedDescription }
            }
        } message: {
            Text("Вложенные категории тоже будут удалены. Наборы из этой категории останутся в библиотеке без категории.")
        }
    }
}

struct SetRow: View {
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    var body: some View {
        HStack {
            Image(systemName: "rectangle.stack").foregroundStyle(.tint).frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(set.name).font(.body.weight(.medium))
                Text("\(store.words(setID: set.id).count) слов").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

struct VocabularySetView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let set: VocabularySet
    @State private var showingWord = false
    @State private var showingImport = false
    @State private var showingCSVExport = false
    @State private var csvDocument = WordCSVDocument(data: Data())
    @State private var showingMoveSet = false
    @State private var showingEditSet = false
    @State private var confirmingDeleteSet = false
    @State private var editingWord: Word?
    @State private var deletingWord: Word?

    private func statusTitle(_ status: WordLearningStatus) -> String {
        switch status {
        case .new: return "Новое"
        case .learning: return "Изучается"
        case .mastered: return "Освоено"
        }
    }

    var body: some View {
        List {
            let words = store.words(setID: set.id)
            let wordProgress = words.compactMap { store.learningProgress(wordID: $0.id) }
            let newCount = words.count - wordProgress.filter { $0.status != .new }.count
            let learningCount = wordProgress.filter { $0.status == .learning }.count
            let masteredCount = wordProgress.filter { $0.status == .mastered }.count
            let correct = wordProgress.reduce(0) { $0 + $1.correctAnswers }
            let incorrect = wordProgress.reduce(0) { $0 + $1.incorrectAnswers }
            let totalAnswers = correct + incorrect
            let accuracy = totalAnswers == 0 ? 0 : Int((Double(correct) / Double(totalAnswers) * 100).rounded())

            if !words.isEmpty {
                Section("Прогресс набора") {
                    LabeledContent("Новые", value: String(newCount))
                    LabeledContent("Изучаются", value: String(learningCount))
                    LabeledContent("Освоены", value: String(masteredCount))
                    LabeledContent("Повторений", value: String(totalAnswers))
                    LabeledContent("Ошибок", value: String(incorrect))
                    LabeledContent("Точность ответов", value: "\(accuracy)%")
                    ProgressView(value: Double(masteredCount), total: Double(max(words.count, 1)))
                }
            }

            if words.isEmpty {
                ContentUnavailableView("Пока нет слов", systemImage: "character.book.closed", description: Text("Добавь первое слово в этот набор."))
            } else {
                ForEach(words) { word in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(word.text).font(.headline)
                        HStack(spacing: 8) {
                            Text(word.translation)
                            if let transcription = word.transcription, !transcription.isEmpty {
                                Text("· \(transcription)").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                        Text(statusTitle(store.learningProgress(wordID: word.id)?.status ?? .new))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("Изменить", systemImage: "pencil") { editingWord = word }
                        Button("Удалить", systemImage: "trash", role: .destructive) { deletingWord = word }
                    }
                }
            }
        }
        .navigationTitle(set.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Добавить слово", systemImage: "plus") { showingWord = true }
                    Button("Импортировать слова", systemImage: "square.and.arrow.down") { showingImport = true }
                    Button("Экспортировать CSV", systemImage: "square.and.arrow.up") {
                        csvDocument = WordCSVDocument(data: WordCSVExporter.data(for: store.words(setID: set.id)))
                        showingCSVExport = true
                    }
                    Button("Переместить набор", systemImage: "folder") { showingMoveSet = true }
                    Button("Изменить набор", systemImage: "pencil") { showingEditSet = true }
                    Button("Удалить набор", systemImage: "trash", role: .destructive) { confirmingDeleteSet = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Действия с набором")
                }
            }
        }
        .sheet(isPresented: $showingWord) { CreateWordSheet(store: store, language: language, set: set) }
        .sheet(isPresented: $showingImport) { ImportWordsSheet(store: store, language: language, set: set) }
        .fileExporter(isPresented: $showingCSVExport, document: csvDocument, contentType: .commaSeparatedText, defaultFilename: "\(set.name)-words", onCompletion: { result in
            if case .failure(let error) = result { store.lastError = error.localizedDescription }
        })
        .sheet(isPresented: $showingMoveSet) { MoveSetSheet(store: store, language: language, set: set) }
        .sheet(isPresented: $showingEditSet) { EditSetSheet(store: store, set: set) }
        .sheet(item: $editingWord) { word in EditWordSheet(store: store, word: word) }
        .confirmationDialog("Удалить набор «\(set.name)»?", isPresented: $confirmingDeleteSet, titleVisibility: .visible) {
            Button("Удалить набор", role: .destructive) {
                do { try store.deleteSet(set.id) } catch { store.lastError = error.localizedDescription }
            }
        } message: {
            Text("Сам набор и его связи будут удалены. Слова останутся в других наборах, если они там используются.")
        }
        .confirmationDialog("Удалить слово «\(deletingWord?.text ?? "")»?", isPresented: Binding(
            get: { deletingWord != nil },
            set: { if !$0 { deletingWord = nil } }
        ), titleVisibility: .visible) {
            Button("Удалить слово", role: .destructive) {
                if let word = deletingWord {
                    do { try store.deleteWord(word.id) } catch { store.lastError = error.localizedDescription }
                }
                deletingWord = nil
            }
        } message: {
            Text("Слово будет удалено из всех наборов вместе с историей обучения.")
        }
    }
}

private struct MoveSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    let set: VocabularySet
    @State private var selectedCategoryID: String
    @State private var error: String?

    init(store: LibraryStore, language: Language, set: VocabularySet) {
        self.store = store
        self.language = language
        self.set = set
        _selectedCategoryID = State(initialValue: set.categoryID ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Расположение", selection: $selectedCategoryID) {
                    Text("Без категории").tag("")
                    ForEach(store.categories(languageID: language.id)) { category in
                        Text(category.name).tag(category.id)
                    }
                }
            }
            .navigationTitle("Переместить набор")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        do {
                            try store.moveSet(set.id, to: selectedCategoryID.isEmpty ? nil : selectedCategoryID)
                            dismiss()
                        } catch let caughtError {
                            error = caughtError.localizedDescription
                        }
                    }
                }
            }
            .alert("Не удалось переместить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}

private struct CreateLanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    @State private var name = ""
    @State private var code = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Например, Китайский", text: $name)
                TextField("Код языка (необязательно)", text: $code)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            .navigationTitle("Новый язык")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        do {
                            try store.createLanguage(name: name, code: code.isEmpty ? nil : code)
                            dismiss()
                        } catch let caughtError { error = caughtError.localizedDescription }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Не удалось создать", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}

private struct CreateCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    let parentID: String?
    @State private var name = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form { TextField("Название категории", text: $name) }
                .navigationTitle(parentID == nil ? "Новая категория" : "Вложенная категория")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Создать") {
                            do {
                                try store.createCategory(languageID: language.id, name: name, parentID: parentID)
                                dismiss()
                            } catch let caughtError { error = caughtError.localizedDescription }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .alert("Не удалось создать", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "") }
        }
    }
}

private struct CreateSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    let categoryID: String?
    @State private var name = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form { TextField("Название набора", text: $name) }
                .navigationTitle("Новый набор")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Создать") {
                            do {
                                try store.createSet(languageID: language.id, name: name, categoryID: categoryID)
                                dismiss()
                            } catch let caughtError { error = caughtError.localizedDescription }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .alert("Не удалось создать", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "") }
        }
    }
}

private struct CreateWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    let set: VocabularySet
    @State private var text = ""
    @State private var translation = ""
    @State private var transcription = ""
    @State private var error: String?
    @State private var duplicate: Word?

    var body: some View {
        NavigationStack {
            Form {
                Section("Карточка") {
                    TextField("Слово", text: $text)
                    TextField("Перевод", text: $translation)
                    TextField("Транскрипция / пиньинь", text: $transcription)
                }
            }
            .navigationTitle("Новое слово")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { addWord() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "Похожая карточка уже существует",
                isPresented: Binding(
                    get: { duplicate != nil },
                    set: { if !$0 { duplicate = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Пропустить") {
                    duplicate = nil
                    dismiss()
                }
                Button("Объединить — использовать существующее слово") {
                    guard let duplicate else { return }
                    do {
                        try store.addWord(duplicate.id, toSet: set.id)
                        self.duplicate = nil
                        dismiss()
                    } catch let caughtError {
                        error = caughtError.localizedDescription
                        self.duplicate = nil
                    }
                }
                Button("Оставить оба", role: .destructive) {
                    createNewWord()
                }
            } message: {
                if let duplicate {
                    Text("«\(duplicate.text)» — «\(duplicate.translation)». Можно добавить существующую карточку в этот набор или создать отдельную.")
                }
            }
            .alert("Не удалось добавить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }

    private func addWord() {
        if let match = store.duplicateWord(languageID: language.id, text: text, translation: translation) {
            duplicate = match
        } else {
            createNewWord()
        }
    }

    private func createNewWord() {
        do {
            try store.createWord(
                languageID: language.id,
                setID: set.id,
                text: text,
                translation: translation,
                transcription: transcription.isEmpty ? nil : transcription
            )
            duplicate = nil
            dismiss()
        } catch let caughtError {
            error = caughtError.localizedDescription
        }
    }
}


private struct EditLanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    @State private var name: String
    @State private var code: String
    @State private var error: String?

    init(store: LibraryStore, language: Language) {
        self.store = store
        self.language = language
        _name = State(initialValue: language.name)
        _code = State(initialValue: language.code ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название языка", text: $name)
                TextField("Код языка", text: $code).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            .navigationTitle("Изменить язык")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        do {
                            try store.updateLanguage(language.id, name: name, code: code.isEmpty ? nil : code)
                            dismiss()
                        } catch { errorMessage(error) }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Не удалось сохранить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }

    private func errorMessage(_ caught: Error) { error = caught.localizedDescription }
}

private struct EditCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let category: Category
    @State private var name: String
    @State private var error: String?

    init(store: LibraryStore, category: Category) {
        self.store = store
        self.category = category
        _name = State(initialValue: category.name)
    }

    var body: some View {
        NavigationStack {
            Form { TextField("Название категории", text: $name) }
                .navigationTitle("Изменить категорию")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") {
                            do {
                                try store.updateCategory(category.id, name: name)
                                dismiss()
                            } catch let caughtError { error = caughtError.localizedDescription }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .alert("Не удалось сохранить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "") }
        }
    }
}

private struct EditSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let set: VocabularySet
    @State private var name: String
    @State private var details: String
    @State private var error: String?

    init(store: LibraryStore, set: VocabularySet) {
        self.store = store
        self.set = set
        _name = State(initialValue: set.name)
        _details = State(initialValue: set.details ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название набора", text: $name)
                TextField("Описание (необязательно)", text: $details, axis: .vertical)
                    .lineLimit(2...5)
            }
            .navigationTitle("Изменить набор")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        do {
                            try store.updateSet(set.id, name: name, details: details)
                            dismiss()
                        } catch let caughtError { error = caughtError.localizedDescription }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Не удалось сохранить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}

private struct EditWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let word: Word
    @State private var text: String
    @State private var translation: String
    @State private var transcription: String
    @State private var error: String?

    init(store: LibraryStore, word: Word) {
        self.store = store
        self.word = word
        _text = State(initialValue: word.text)
        _translation = State(initialValue: word.translation)
        _transcription = State(initialValue: word.transcription ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Слово", text: $text)
                TextField("Перевод", text: $translation)
                TextField("Транскрипция / пиньинь", text: $transcription)
            }
            .navigationTitle("Изменить слово")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        do {
                            try store.updateWord(
                                word.id,
                                text: text,
                                translation: translation,
                                transcription: transcription.isEmpty ? nil : transcription
                            )
                            dismiss()
                        } catch let caughtError { error = caughtError.localizedDescription }
                    }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Не удалось сохранить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}
