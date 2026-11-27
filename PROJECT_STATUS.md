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
- CI: GitHub Actions on macOS; CI run #55 is green.
- Development machine: Windows 11; all Xcode builds and XCTest run in GitHub Actions.

## Latest verified baseline

- Commit: `531a8aa` — `test(import): align quoted CSV fixture with column mapping`.
- Workflow run #55: successful iOS Simulator build and XCTest.
- Import coverage now includes text pairs, CSV/TSV/TXT, XLSX, PDF text extraction, image OCR, scanned-PDF OCR, multiline quoted CSV fields, escaped quotes, and malformed quoted-field rejection.
- OCR uses Apple Vision on-device; scanned PDF pages are rasterized and passed through the same recognition pipeline.
- CSV parser handles comma, semicolon, and tab delimiters, quoted delimiters, embedded newlines, CRLF, and doubled quote escaping.

## Current implementation

### Persistence and library

- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite and an in-memory initializer for isolated tests.
- Versioned migrations for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- Repository operations for language/category/set/word creation, editing/deletion, set movement, set membership, and library reads.
- Duplicate detection is language-scoped; users can skip, keep both, or merge.
- Shared words retain a single word-level learning history across sets.
- Global search covers original words, translations, set names, and category names; word results include all containing sets.

### Learning and games

- SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date.
- Flashcards, multiple-choice, and typed-answer sessions share SRS answer recording.
- Due-review queue, weak-word practice, and deduplicated Mix Sets.
- Pairs, Audio choice (system TTS), Speed (60-second typing), and Missing (sentence completion) games.
- Games are independent practice and do not alter SRS.

### Import

- Paste tab-, comma-, or semicolon-delimited word pairs with editable preview.
- CSV, TSV, TXT, and XLSX file import; XLSX supports worksheet selection and configurable column mapping.
- UTF-8, UTF-16, and Windows-1251 text decoding fallback.
- PDF text-layer extraction and scanned/image-only PDF OCR.
- Image and screenshot OCR via Apple Vision, processed on device.
- All imported rows pass through editable preview, required-field validation, duplicate resolution, and transactional save.
- Parser and repository tests cover metadata, duplicate policies, transaction rollback, malformed input, quoted delimiters, multiline values, and missing target sets.

## Known product gaps

- AI, Sets, and Profile tabs are still placeholders or incomplete; AI generation is the next major implementation milestone.
- Onboarding, pronunciation recording/feedback, statistics/calendar, reminders, backup/restore, export, and device installation workflow remain.
- Simulator CI success does not mean an installable, signed iPhone build has been produced.

## Verification policy

GitHub Actions on macos-latest is authoritative because development is performed on Windows without Xcode. A feature is marked verified only after the iOS Simulator build and XCTest pass.

## Next

Implement the AI foundation: provider abstraction, Keychain-backed user API-key storage, Gemini vocabulary generation, robust response parsing, and an editable review flow before any generated cards are saved.
