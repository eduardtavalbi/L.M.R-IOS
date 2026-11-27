import SwiftUI

/// A cross-language index of all vocabulary sets, with direct access to set details.
struct SetsView: View {
    @ObservedObject var store: LibraryStore
    @State private var searchText = ""

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
                        description: Text("Сначала добавь язык во вкладке «Главная», затем создавай наборы слов.")
                    )
                } else {
                    List {
                        ForEach(store.languages) { language in
                            let sets = filteredSets(for: language)
                            Section {
                                if sets.isEmpty {
                                    Text(query.isEmpty ? "Наборов пока нет" : "Совпадений не найдено")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(sets) { set in
                                        NavigationLink {
                                            VocabularySetView(store: store, language: language, set: set)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 5) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "rectangle.stack")
                                                        .foregroundStyle(.tint)
                                                    Text(set.name)
                                                        .font(.body.weight(.medium))
                                                }
                                                if let details = set.details, !details.isEmpty {
                                                    Text(details)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(2)
                                                }
                                                Text("\(store.words(setID: set.id).count) слов")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.vertical, 3)
                                        }
                                    }
                                }

                                NavigationLink {
                                    LanguageLibraryView(store: store, language: language)
                                } label: {
                                    Label("Категории и управление", systemImage: "folder")
                                        .font(.subheadline)
                                }
                            } header: {
                                HStack {
                                    Text(language.name)
                                    Spacer()
                                    Text("\(store.allSets(languageID: language.id).count)")
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
                        ForEach(store.languages) { language in
                            NavigationLink {
                                LanguageLibraryView(store: store, language: language)
                            } label: {
                                Label("Открыть \(language.name)", systemImage: "plus")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Создать набор")
                }
            }
        }
    }

    private func filteredSets(for language: Language) -> [VocabularySet] {
        let sets = store.allSets(languageID: language.id)
        guard !query.isEmpty else { return sets }
        return sets.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
