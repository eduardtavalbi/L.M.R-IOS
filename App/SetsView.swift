import SwiftUI

/// A cross-language catalogue of sets, including their nested category locations.
struct SetsView: View {
    @ObservedObject var store: LibraryStore
    @State private var searchText = ""
    @State private var showingCreateSet = false
    @State private var sortOrder: SetCatalogueSort = .name

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.languages.isEmpty {
                    ContentUnavailableView(
                        "Пока нет языков",
                        systemImage: "character.book.closed",
                        description: Text("Сначала добавь язык во вкладке «Главная».")
                    )
                } else {
                    List {
                        ForEach(store.languages) { language in
                            let sets = store.allSets(languageID: language.id)
                            let filteredSets = query.isEmpty
                                ? sets
                                : sets.filter { $0.name.localizedCaseInsensitiveContains(query) }
                            let visibleSets = sortOrder.sorted(filteredSets, wordCount: { store.words(setID: $0.id).count })

                            Section {
                                if query.isEmpty {
                                    let uncategorized = sortOrder.sorted(sets.filter { $0.categoryID == nil }, wordCount: { store.words(setID: $0.id).count })
                                    if !uncategorized.isEmpty {
                                        DisclosureGroup("Без категории · \(uncategorized.count)") {
                                            ForEach(uncategorized) { set in
                                                setLink(set, language: language)
                                            }
                                        }
                                    }
                                    ForEach(store.categories(languageID: language.id).filter { $0.parentID == nil }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) { category in
                                        CategorySetGroup(
                                            store: store,
                                            language: language,
                                            category: category,
                                            query: query,
                                            sortOrder: sortOrder
                                        )
                                    }
                                    if sets.isEmpty && store.categories(languageID: language.id).isEmpty {
                                        ContentUnavailableView(
                                            "Нет наборов",
                                            systemImage: "rectangle.stack",
                                            description: Text("Нажми «+», чтобы создать первый набор.")
                                        )
                                    }
                                } else {
                                    if visibleSets.isEmpty {
                                        Text("Совпадений не найдено")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ForEach(visibleSets) { set in
                                            setLink(set, language: language)
                                        }
                                    }
                                }

                                NavigationLink {
                                    LanguageLibraryView(store: store, language: language)
                                } label: {
                                    Label("Управление категориями", systemImage: "folder")
                                        .font(.subheadline)
                                }
                            } header: {
                                HStack {
                                    Text(language.name)
                                    Spacer()
                                    Text("\(sets.count) наборов")
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Наборы")
            .searchable(text: $searchText, prompt: "Поиск по названию набора")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Сортировка", selection: $sortOrder) {
                            ForEach(SetCatalogueSort.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Сортировка наборов")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateSet = true } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(store.languages.isEmpty)
                    .accessibilityLabel("Создать набор")
                }
            }
            .sheet(isPresented: $showingCreateSet) {
                QuickCreateSetSheet(store: store)
            }
        }
    }

    @ViewBuilder
    private func setLink(_ set: VocabularySet, language: Language) -> some View {
        NavigationLink {
            VocabularySetView(store: store, language: language, set: set)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.stack")
                    .foregroundStyle(.tint)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.name).font(.body.weight(.medium))
                    if let details = set.details, !details.isEmpty {
                        Text(details).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Text("\(store.words(setID: set.id).count) слов")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
        }
    }
}

private enum SetCatalogueSort: String, CaseIterable, Identifiable {
    case name
    case newest
    case mostWords

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: return "По названию"
        case .newest: return "Сначала новые"
        case .mostWords: return "По количеству слов"
        }
    }

    func sorted(_ sets: [VocabularySet], wordCount: (VocabularySet) -> Int) -> [VocabularySet] {
        switch self {
        case .name:
            return sets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .newest:
            return sets.sorted {
                if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        case .mostWords:
            return sets.sorted {
                let left = wordCount($0)
                let right = wordCount($1)
                if left != right { return left > right }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        }
    }
}

private struct CategorySetGroup: View {
    @ObservedObject var store: LibraryStore
    let language: Language
    let category: Category
    let query: String
    let sortOrder: SetCatalogueSort

    private var sets: [VocabularySet] {
        let all = store.sets(languageID: language.id, categoryID: category.id)
        let filtered = query.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(query) }
        return sortOrder.sorted(filtered, wordCount: { store.words(setID: $0.id).count })
    }

    private var children: [Category] {
        store.categories(languageID: language.id, parentID: category.id)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        DisclosureGroup {
            ForEach(sets) { set in
                NavigationLink {
                    VocabularySetView(store: store, language: language, set: set)
                } label: {
                    HStack {
                        Text(set.name)
                        Spacer()
                        Text("\(store.words(setID: set.id).count)")
                            .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
            ForEach(children) { child in
                CategorySetGroup(store: store, language: language, category: child, query: query, sortOrder: sortOrder)
            }
            if sets.isEmpty && children.isEmpty {
                Text("Пустая категория")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } label: {
            Label {
                HStack {
                    Text(category.name)
                    Spacer()
                    Text("\(store.sets(languageID: language.id, categoryID: category.id).count)")
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
            } icon: {
                Image(systemName: "folder")
            }
        }
    }
}

private struct QuickCreateSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    @State private var languageID = ""
    @State private var categoryID = ""
    @State private var name = ""
    @State private var details = ""
    @State private var error: String?

    private var categories: [Category] {
        guard !languageID.isEmpty else { return [] }
        return store.categories(languageID: languageID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Набор") {
                    Picker("Язык", selection: $languageID) {
                        ForEach(store.languages) { language in
                            Text(language.name).tag(language.id)
                        }
                    }
                    TextField("Название набора", text: $name)
                    TextField("Описание (необязательно)", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Расположение") {
                    Picker("Категория", selection: $categoryID) {
                        Text("Без категории").tag("")
                        ForEach(categories) { category in
                            Text(categoryPath(category)).tag(category.id)
                        }
                    }
                }
            }
            .navigationTitle("Новый набор")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || languageID.isEmpty)
                }
            }
            .onAppear {
                if languageID.isEmpty { languageID = store.languages.first?.id ?? "" }
            }
            .onChange(of: languageID) { _, _ in categoryID = "" }
            .alert("Не удалось создать набор", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func categoryPath(_ category: Category) -> String {
        guard let parentID = category.parentID,
              let parent = categories.first(where: { $0.id == parentID }) else {
            return category.name
        }
        return categoryPath(parent) + " / " + category.name
    }

    private func create() {
        do {
            try store.createSet(
                languageID: languageID,
                name: name,
                categoryID: categoryID.isEmpty ? nil : categoryID,
                details: details
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
