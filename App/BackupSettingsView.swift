import SwiftUI
import UniformTypeIdentifiers

struct LibraryBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupSettingsView: View {
    @ObservedObject var store: LibraryStore
    @State private var exportDocument = LibraryBackupDocument(data: Data())
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingRestore: Data?
    @State private var confirmRestore = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Резервная копия").font(.headline)
            Button {
                do {
                    exportDocument = LibraryBackupDocument(data: try store.makeBackupData())
                    isExporting = true
                } catch {
                    message = "Не удалось создать резервную копию: \(error.localizedDescription)"
                }
            } label: {
                Label("Сохранить копию словаря", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Button {
                isImporting = true
            } label: {
                Label("Восстановить из файла", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Text("Копия включает языки, категории, наборы, слова, связи между наборами, интервалы повторения и календарь занятий. Восстановление заменит текущую библиотеку.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "LMR-Backup",
            onCompletion: { result in
                if case .failure(let error) = result {
                    message = "Не удалось сохранить файл: \(error.localizedDescription)"
                }
            }
        )
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: url)
                    _ = try LibraryBackup.decode(data)
                    pendingRestore = data
                    confirmRestore = true
                } catch {
                    message = "Файл не подходит для восстановления: \(error.localizedDescription)"
                }
            case .failure(let error):
                message = "Не удалось открыть файл: \(error.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Заменить текущую библиотеку?",
            isPresented: $confirmRestore,
            titleVisibility: .visible
        ) {
            Button("Заменить библиотеку", role: .destructive) {
                guard let pendingRestore else { return }
                do {
                    try store.restoreBackup(data: pendingRestore)
                    self.pendingRestore = nil
                    message = "Библиотека успешно восстановлена."
                } catch {
                    message = "Восстановление не выполнено: \(error.localizedDescription)"
                }
            }
            Button("Отмена", role: .cancel) { pendingRestore = nil }
        } message: {
            Text("Все текущие языки, наборы и слова будут заменены содержимым выбранной копии.")
        }
        .alert("Резервная копия", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("Понятно", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }
}
