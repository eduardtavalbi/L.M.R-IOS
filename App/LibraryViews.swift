import SwiftUI

struct LibraryView: View {
    @ObservedObject var store: LibraryStore
    @State private var showingCreateLanguage = false

    var body: some View {
        NavigationStack {
            Group {
                if store.languages.isEmpty {
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
                                            .font(.title2)
                                            .foregroundStyle(.tint)
                                            .frame(width: 42, height: 42)
                                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(language.name).font(.headline)
                                            Text(language.code?.uppercased() ?? "Язык")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateLanguage = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить язык")
                }
            }
            .sheet(isPresented: $showingCreateLanguage) {
                CreateLanguageSheet(store: store)
            }
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

struct LanguageLibraryView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    @State private var showingCategory = false
    @State private var showingSet = false

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
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCategory) {
            CreateCategorySheet(store: store, language: language, parentID: nil)
        }
        .sheet(isPresented: $showingSet) {
            CreateSetSheet(store: store, language: language, categoryID: nil)
        }
    }
}

struct CategoryLibraryView: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let category: Category
    @State private var showingCategory = false
    @State private var showingSet = false

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
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCategory) {
            CreateCategorySheet(store: store, language: language, parentID: category.id)
        }
        .sheet(isPresented: $showingSet) {
            CreateSetSheet(store: store, language: language, categoryID: category.id)
        }
    }
}

struct SetRow: View {
    @ObservedObject var store: LibraryStore
    let set: VocabularySet

    var body: some View {
        HStack {
            Image(systemName: "rectangle.stack")
                .foregroundStyle(.tint)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(set.name).font(.body.weight(.medium))
                Text("\(store.words(setID: set.id).count) слов")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
    @State private var showingMoveSet = false

    var body: some View {
        List {
            let words = store.words(setID: set.id)
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
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(set.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Добавить слово", systemImage: "plus") { showingWord = true }
                    Button("Переместить набор", systemImage: "folder") { showingMoveSet = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingWord) {
            CreateWordSheet(store: store, language: language, set: set)
        }
        .sheet(isPresented: $showingMoveSet) {
            MoveSetSheet(store: store, language: language, set: set)
        }
    }
}

private struct MoveSetSheet: View {
    @Environment(\\.dismiss) private var dismiss
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                    Button("Добавить") {
                        do {
                            try store.createWord(
                                languageID: language.id,
                                setID: set.id,
                                text: text,
                                translation: translation,
                                transcription: transcription.isEmpty ? nil : transcription
                            )
                            dismiss()
                        } catch let caughtError { error = caughtError.localizedDescription }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Не удалось добавить", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}
