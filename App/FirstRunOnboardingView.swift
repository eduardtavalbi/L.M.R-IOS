import SwiftUI

struct FirstRunOnboardingView: View {
    @ObservedObject var store: LibraryStore
    let onComplete: () -> Void

    @State private var selectedCodes: Set<String> = ["zh", "en"]
    @State private var errorMessage: String?

    private var selectedLanguages: [OnboardingLanguage] {
        OnboardingLanguage.suggested.filter { selectedCodes.contains($0.code) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.tint)
                        Text("Добро пожаловать в L.M.R.")
                            .font(.largeTitle.bold())
                        Text("Learn. Memorize. Repeat.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Выбери языки, которые хочешь изучать. Позже ты сможешь добавить другие и изменить библиотеку.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Мои языки").font(.title3.bold())
                        Text("Китайский и английский уже выбраны — отметь или сними выбор по своему желанию.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(OnboardingLanguage.suggested) { language in
                            Button {
                                toggle(language.code)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedCodes.contains(language.code) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selectedCodes.contains(language.code) ? .tint : .secondary)
                                    Text(language.name).foregroundStyle(.primary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selectedCodes.contains(language.code) ? .isSelected : [])
                        }
                    }

                    Button(action: createSelectedLanguages) {
                        Text(selectedCodes.isEmpty ? "Продолжить без языков" : "Начать · \(selectedCodes.count)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Пропустить — настрою позже", action: onComplete)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Первый запуск").font(.headline)
                }
            }
            .alert("Не удалось сохранить языки", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .interactiveDismissDisabled()
    }

    private func toggle(_ code: String) {
        if selectedCodes.contains(code) {
            selectedCodes.remove(code)
        } else {
            selectedCodes.insert(code)
        }
    }

    private func createSelectedLanguages() {
        do {
            for language in selectedLanguages where !store.languages.contains(where: { $0.code == language.code }) {
                try store.createLanguage(name: language.name, code: language.code)
            }
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
