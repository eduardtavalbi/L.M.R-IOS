# L.M.R. — Project Status

Last updated: 2026-11-27

## Product

**L.M.R. — Learn. Memorize. Repeat.**  
Russian slogan: «Учись. Запоминай. Повторяй.»

A personal, non-commercial, offline-first iOS language-learning app. Native SwiftUI, iOS 17+.

## Repository and delivery

- Repository: https://github.com/eduardtavalbi/L.M.R-IOS
- Working branch: main
- Project generation: XcodeGen (`project.yml`)
- CI: GitHub Actions on macOS; latest verified AI foundation run #57 is green.
- Development machine: Windows 11; all Xcode builds and XCTest run in GitHub Actions.

## Latest verified baseline

- Commit: `ff26269` — `feat(ai): add Gemini provider and Keychain secret storage`.
- Workflow run #57: successful iOS Simulator build and XCTest.
- Import coverage includes text pairs, CSV/TSV/TXT, XLSX, PDF text extraction, image OCR, scanned-PDF OCR, multiline quoted CSV fields, escaped quotes, and malformed quoted-field rejection.
- OCR uses Apple Vision on-device; scanned PDF pages are rasterized and passed through the same recognition pipeline.

## Current implementation

### Persistence and library
- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite and an in-memory initializer for isolated tests.
- Versioned migrations for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- Repository operations for language/category/set/word CRUD, set movement, membership, duplicate resolution, and global search.
- Shared words retain a single word-level learning history across sets.

### Learning and games
- SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date.
- Flashcards, multiple-choice, typed-answer sessions, due-review queue, weak-word practice, and Mix Sets.
- Pairs, Audio choice (system TTS), Speed typing, and Missing-word games.

### Import
- Paste text, CSV/TSV/TXT, XLSX with worksheet/column mapping, PDF text extraction, image OCR, and scanned-PDF OCR.
- Imports pass through editable preview, validation, duplicate resolution, and transactional save.

### AI
- Provider protocol and request/response models.
- Gemini generateContent client with JSON response parsing and input validation.
- API key stored in iOS Keychain; no secret is embedded in source.
- AI screen now supports key setup, topic/language/level/count, generation, editable draft review, and explicit save to a selected set. Generated content stays in memory until the user confirms saving.

## Known gaps

- AI document extraction, enrichment, weak-word analysis, and AI Mix Sets remain.
- Sets and Profile tabs remain incomplete.
- Onboarding, pronunciation recording/feedback, statistics/calendar, reminders, backup/restore, export, and device installation workflow remain.
- Simulator CI success does not mean a signed/installable iPhone build has been produced.

## Verification policy

GitHub Actions on macos-latest is authoritative because development is performed on Windows without Xcode. A feature is verified only after the iOS Simulator build and XCTest pass.

## Next

Verify the AI screen in CI, then improve generated-card persistence (including notes/explanations), add provider tests with a mocked network session, and continue the Sets/Profile experience.
