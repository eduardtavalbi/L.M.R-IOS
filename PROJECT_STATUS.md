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
- CI: GitHub Actions on macOS; latest verified run #99 is green.
- Development machine: Windows 11; all Xcode builds and XCTest run in GitHub Actions.

## Latest verified baseline

- Commit: `3aa5ebc` — category-path search in the Sets catalogue; CI #99 is green. Commit `4983826` caches word counts during sorting; CI #98 is green.
- Commit: `9239139` — first-run language onboarding; CI #96 is green.
- Commit: `84d7d30` — pinyin tone hints and Unicode-compatible numeric tone parsing.
- Workflow run #94: successful iOS Simulator build and XCTest, including tone-mark and numbered-pinyin tests.
- Workflow run #92: successful iOS Simulator build and XCTest, including pronunciation normalization and language-locale tests.
- Reference speech, personal voice recording/playback, and English US/UK voice selection are verified by CI #91.
- CSV export and per-set review/error statistics are verified by CI #89.
- Import coverage includes text pairs, CSV/TSV/TXT, XLSX, PDF text extraction, image OCR, scanned-PDF OCR, multiline quoted CSV fields, escaped quotes, and malformed quoted-field rejection.
- OCR uses Apple Vision on-device; scanned PDF pages are rasterized and passed through the same recognition pipeline.
- Gemini API tests cover a successful response, HTTP 429 mapping, and missing API-key handling.

## Current implementation

### Persistence and library
- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite and an in-memory initializer for isolated tests.
- Versioned migrations for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- Repository operations for language/category/set/word CRUD, set movement, membership, duplicate resolution, and global search.
- Shared words retain a single word-level learning history across sets.
- Library screens support nested categories, uncategorized sets, set detail, word CRUD, import, and moving sets.

### Learning and games
- SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date.
- Flashcards, multiple-choice, typed-answer sessions, due-review queue, weak-word practice, and Mix Sets.
- Pairs, Audio choice (system TTS), Speed typing, and Missing-word games.

### Pronunciation
- System text-to-speech reference playback, with US/UK English voice choice.
- Per-word AAC voice recording and playback stored locally on the device.
- Speech recognition compares recognized text with the card's original word and shows transparent text-match feedback; no acoustic score or tone analysis is claimed.
- Chinese cards show pinyin tone hints for tone diacritics and numeric notation (1–5); these are reading aids, not microphone-based tone scoring.
- Speech and microphone permission descriptions are configured in the generated Info.plist.

### Import
- Paste text, CSV/TSV/TXT, XLSX with worksheet/column mapping, PDF text extraction, image OCR, and scanned-PDF OCR.
- Imports pass through editable preview, validation, duplicate resolution, and transactional save.

### AI
- Provider protocol and request/response models.
- Gemini generateContent client with JSON response parsing and input validation.
- API key stored in iOS Keychain; no secret is embedded in source.
- AI screen supports key setup, topic/language/level/count, generation, editable draft review, and explicit save to a selected set.\n- AI document extraction sends extracted PDF/text/OCR content to Gemini, returns distinct vocabulary entries, and reuses the import preview and duplicate-resolution flow; source text is capped at 30,000 characters.
- Generated examples and explanations are saved separately; generated content stays in memory until the user confirms saving.

### Sets tab
- Cross-language set catalogue with per-language grouping, nested category disclosure, uncategorized sets, search by set name or any level of its category path, and sorting by name, creation date, or word count.
- Quick set creation directly from the Sets tab, with language, nested category path, and optional description.
- Direct navigation to set detail and to the language's category-management/library screen.
- Set detail supports adding/editing/deleting words, importing, editing set metadata, and moving a set between categories.

### Profile and learning history
- Seven milestone achievements with live progress and unlock states.
- Daily local notification reminders with an in-app time picker and permission handling.
- Set detail statistics include total answers and incorrect answers alongside accuracy and mastered-word progress.
- Versioned daily activity table, updated atomically with every SRS answer.
- Profile dashboard: vocabulary total, mastered count, total reviews, answer accuracy, current study streak, and total study days.
- Monthly activity calendar and monthly totals for study days, reviews, and first-time reviewed words.
- Activity aggregation and streak behavior covered by repository tests.

### Backup and export
- JSON backup includes languages, nested categories, sets, words, shared-word memberships, SRS progress, and study activity.
- Restore validates the schema and references before replacing the library in a database transaction; the UI requires explicit destructive-action confirmation.
- CSV export includes vocabulary, translations, transcription, notes, and examples, with UTF-8 BOM and quoting for delimiters, quotes, and multiline fields.

## Known gaps

- Sets tab category search now matches full nested paths and shows the matched set's category location; category-level filtering/navigation can be refined further.
- AI document enrichment, weak-word analysis, and AI Mix Sets remain.
- First-run onboarding is implemented and verified by CI #96; users can select suggested languages or skip setup.
- Accessibility/Dynamic Type and device installation workflow remain.
- Speech recognition availability and quality depend on iOS language support, device settings, and network/on-device recognizer behavior.
- Simulator CI success does not mean a signed/installable iPhone build has been produced.

## Verification policy

GitHub Actions on macos-latest is authoritative because development is performed on Windows without Xcode. A feature is verified only after the iOS Simulator build and XCTest pass.

## Next

Next: continue AI workflows (document extraction, enrichment, weak-word analysis, and AI Mix Sets), then accessibility and delivery hardening. Device packaging remains a separate final milestone.
