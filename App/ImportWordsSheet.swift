import SwiftUI

struct ImportWordsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LibraryStore
    let language: Language
    let set: VocabularySet

    @State private var source = ""
    @State private var rows: [WordImportDraft] = []
    @State private var showingPreview = false
    @State private var error: String?
    @State private var summary: WordImportSummary?

    private var validRows: [WordImportDraft] {
        rows.filter { $0.validationError == nil }
    }

    private var invalidCount: Int {
        rows.count - validRows.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if let summary {
                    resultView(summary)
                } else if showingPreview {
                    previewView
                } else {
                    inputView
                }
            }
            .navigationTitle(showingPreview ? "Проверка импорта" : "Импорт слов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(summary == nil ? "Закрыть" : "Готово") { dismiss() }
                }
                if showingPreview && summary == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Импортировать") { importRows() }
                            .disabled(validRows.isEmpty || invalidCount > 0)
                    }
                }
            }
            .alert("Не удалось выполнить импорт", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private var inputView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Вставь пары слов из таблицы или текстового файла.")
                .font(.headline)
            Text("Поддерживаются TAB, запятая и точка с запятой. Колонки: слово, перевод, транскрипция, пример. Последние две необязательны.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if source.isEmpty {
                    Text("apple\tяблоко\nbook\tкнига\nhello\tпривет\thəˈləʊ\tHello!")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $source)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
                    .padding(4)
            }
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary) }
            Button("Разобрать и проверить") { parseSource() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var previewView: some View {
        List {
            Section {
                LabeledContent("Набор", value: set.name)
                LabeledContent("Строк", value: "\(rows.count)")
                if invalidCount > 0 {
                    Label("\(invalidCount) строк требуют исправления", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            ForEach($rows) { $row in
                let duplicate = store.duplicateWord(
                    languageID: language.id,
                    text: row.text,
                    translation: row.translation
                )
                Section {
                    TextField("Иностранное слово", text: $row.text)
                        .textInputAutocapitalization(.never)
                    TextField("Перевод", text: $row.translation)
                    TextField("Транскрипция / пиньинь", text: $row.transcription)
                    TextField("Пример (необязательно)", text: $row.example, axis: .vertical)
                        .lineLimit(1...3)
                    if let validationError = row.validationError {
                        Label(validationError, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if let duplicate {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Похожая карточка уже есть", systemImage: "doc.on.doc")
                                .font(.subheadline.weight(.medium))
                            Text("\(duplicate.text) — \(duplicate.translation)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Действие", selection: $row.duplicateResolution) {
                                ForEach(ImportDuplicateResolution.allCases) { resolution in
                                    Text(resolution.title).tag(resolution)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Карточка \(rows.firstIndex(where: { $0.id == row.id }).map { $0 + 1 } ?? 0)")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func resultView(_ summary: WordImportSummary) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(.green)
            Text("Импорт завершён")
                .font(.title2.weight(.semibold))
            LabeledContent("Добавлено новых", value: "\(summary.imported)")
            LabeledContent("Объединено с существующими", value: "\(summary.merged)")
            LabeledContent("Пропущено", value: "\(summary.skipped)")
            Button("Готово") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func parseSource() {
        do {
            rows = try WordImportParser.parse(source)
            guard !rows.isEmpty else { throw WordImportParser.ParseError.noRows }
            showingPreview = true
        } catch {
            self.error = "Не удалось распознать строки. Используй две обязательные колонки: слово и перевод."
        }
    }

    private func importRows() {
        do {
            summary = try store.importWords(validRows, intoSet: set.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
