import SwiftUI
import UniformTypeIdentifiers

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
    @State private var showingFileImporter = false
    @State private var xlsxWorksheets: [XLSXWorksheet] = []
    @State private var selectedWorksheetID = ""
    @State private var wordColumn = 0
    @State private var translationColumn = 1
    @State private var transcriptionColumn = 2
    @State private var exampleColumn = 3
    @State private var hasAIKey = false
    @State private var isAIExtracting = false
    @State private var translationLanguage = "Русский"

    private var validRows: [WordImportDraft] {
        rows.filter { $0.validationError == nil }
    }

    private var invalidCount: Int {
        rows.count - validRows.count
    }

    private var selectedWorksheet: XLSXWorksheet? {
        xlsxWorksheets.first { $0.id == selectedWorksheetID }
    }

    private var spreadsheetColumnCount: Int {
        max(selectedWorksheet?.rows.map(\.count).max() ?? 0, 2)
    }

    private var spreadsheetColumnOptions: [Int] {
        Array(0..<max(spreadsheetColumnCount, 4))
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
            .task {
                hasAIKey = (try? KeychainSecretStore().readSecret(for: "gemini.apiKey")) != nil
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .pdf, .image, UTType(filenameExtension: "xlsx") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                loadSelectedFile(result)
            }
        }
    }

    private var inputView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Вставь пары слов из таблицы или выбери файл.")
                .font(.headline)
            Text("Поддерживаются CSV, TSV, TXT, XLSX, PDF и изображения. Фото и сканы распознаются на устройстве; текст перед сохранением можно проверить и исправить. Колонки: слово, перевод, транскрипция, пример.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !xlsxWorksheets.isEmpty {
                GroupBox("Настройки Excel") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Лист", selection: $selectedWorksheetID) {
                            ForEach(xlsxWorksheets) { worksheet in
                                Text(worksheet.name).tag(worksheet.id)
                            }
                        }
                        columnPicker("Слово", selection: $wordColumn)
                        columnPicker("Перевод", selection: $translationColumn)
                        columnPicker("Транскрипция", selection: $transcriptionColumn)
                        columnPicker("Пример", selection: $exampleColumn)
                    }
                }
            } else {
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
            }

            if !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                GroupBox("Извлечение слов с AI") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Язык перевода", text: $translationLanguage)
                        if hasAIKey {
                            Button {
                                Task { await extractWithAI() }
                            } label: {
                                HStack {
                                    if isAIExtracting { ProgressView() }
                                    Text(isAIExtracting ? "Анализирую документ…" : "Извлечь слова с Gemini")
                                }
                            }
                            .disabled(isAIExtracting || translationLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        } else {
                            Text("Добавь Gemini API-ключ во вкладке AI, чтобы извлекать карточки из документа.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("AI предложит слова и переводы. Перед импортом ты сможешь проверить, исправить и удалить каждую карточку.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Выбрать файл или изображение", systemImage: "doc") {
                showingFileImporter = true
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Button("Разобрать и проверить") { parseSource() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(xlsxWorksheets.isEmpty && source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer(minLength: 0)
        }
        .padding()
    }

    private func columnPicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(spreadsheetColumnOptions, id: \.self) { index in
                Text(excelColumnName(index)).tag(index)
            }
        }
    }

    private func excelColumnName(_ index: Int) -> String {
        var value = index + 1
        var result = ""
        while value > 0 {
            let remainder = (value - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            value = (value - 1) / 26
        }
        return result
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
                .font(.largeTitle)
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

    private func loadSelectedFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            if url.pathExtension.lowercased() == "pdf" {
                xlsxWorksheets = []
                do {
                    source = try PDFImportParser.extractText(from: data)
                } catch PDFImportParser.ParseError.noExtractableText {
                    source = try ImageOCRParser.extractText(fromPDFData: data)
                }
                return
            }
            if UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true {
                xlsxWorksheets = []
                source = try ImageOCRParser.extractText(fromImageData: data)
                return
            }
            if url.pathExtension.lowercased() == "xlsx" {
                xlsxWorksheets = try XLSXImportParser.parse(data: data)
                selectedWorksheetID = xlsxWorksheets.first?.id ?? ""
                source = ""
                wordColumn = 0
                translationColumn = 1
                transcriptionColumn = 2
                exampleColumn = 3
                return
            }

            xlsxWorksheets = []
            guard let fileText = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .utf16)
                    ?? String(data: data, encoding: .windowsCP1251) else {
                error = "Не удалось прочитать файл. Сохрани его в UTF-8 и попробуй снова."
                return
            }
            source = fileText
        } catch {
            self.error = "Не удалось открыть файл: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func extractWithAI() async {
        isAIExtracting = true
        defer { isAIExtracting = false }
        do {
            let request = AIImportRequest(
                sourceText: source,
                sourceLanguage: language.name,
                targetLanguage: translationLanguage,
                maxWords: 100
            )
            let extracted = try await GeminiVocabularyProvider().extractVocabulary(from: request)
            rows = extracted.map { word in
                WordImportDraft(
                    text: word.text,
                    translation: word.translation,
                    transcription: word.transcription ?? "",
                    example: word.example ?? ""
                )
            }
            guard !rows.isEmpty else { throw AIGenerationError.invalidResponse }
            showingPreview = true
        } catch {
            self.error = "Не удалось извлечь слова с AI: \(error.localizedDescription)"
        }
    }

    private func parseSource() {
        do {
            if let worksheet = selectedWorksheet {
                rows = try WordImportParser.parse(
                    rows: worksheet.rows,
                    columnIndices: [wordColumn, translationColumn, transcriptionColumn, exampleColumn]
                )
            } else {
                rows = try WordImportParser.parse(source)
            }
            guard !rows.isEmpty else { throw WordImportParser.ParseError.noRows }
            showingPreview = true
        } catch {
            self.error = "Не удалось распознать строки. Проверь лист и соответствие колонок: слово и перевод обязательны."
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
