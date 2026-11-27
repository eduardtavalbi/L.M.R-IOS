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
- CI: GitHub Actions on macOS; latest verified workflow run #45995703782 on commit `bfae965` passed both iOS Simulator build/XCTest and unsigned iOS-device Release IPA packaging.
- Development machine: Windows; Xcode builds and XCTest run in GitHub Actions.

## Latest verified baseline

- Commit: `bfae965` — corrected shell continuations in the SideStore packaging workflow; workflow run #45995703782 passed simulator build, XCTest, device Release build, IPA assembly/validation, and artifact upload. Artifact `LMR-SideStore-unsigned-IPA` (3,126,718 bytes; SHA-256 `dea5b2b2da15cd782b1c9a81c22b71188eea5142ad2259e01f1e48ea70956778`) is available until 2026-12-11.
- Commit: `dbed46e` — backup restore now rejects duplicate word-to-set memberships before modifying the database; iOS Simulator build and XCTest passed in workflow run #45994078206.
- Commit: `5305838` — speech recognition is on-device-only when supported; recordings are stored under Application Support and excluded from backup. CI run #45991975035 passed.
- Commit: `8a586ab` — batched global-search word-to-set lookup; iOS Simulator build and XCTest passed in workflow run #45990196080.
- Commit: `ee5f703` — SQL-based set word and due-review counts; iOS Simulator build and XCTest passed in workflow run #45988166494.
- Commit: `7c19156` — Gemini data-processing disclosures; iOS Simulator build and XCTest passed in workflow run #45986246891.
- Commit: `a736602` — VoiceOver labels and values for core library, learning progress, game timers, set selection, and catalogue actions; latest relevant accessibility CI run #45983308627 passed.
- Dynamic Type updates replaced fixed large text sizes in core learning screens, games, onboarding, and import review; the accessibility-related workflow runs passed.
- Commit: `8d94f00` — AI Mix Sets implementation and compile fixes; build and XCTest passed in workflow run #45978494297.
- Commit: `23b321f` — AI weak-word analysis; build and XCTest passed in workflow run #45976200195.
- Commit: `62cb5a7` — reviewable AI vocabulary enrichment workflow; build and XCTest passed in workflow run #45974032162.
- Commit: `4f7b223` — Gemini document vocabulary extraction; CI run #45969493513 passed.
- Earlier verified milestones include category-path search (CI #99), onboarding (CI #96), pinyin tone hints (CI #94), pronunciation and speech recognition (CI #92), CSV export (CI #89), and backup/restore (CI #86).

## Current implementation

### Persistence and library
- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite and an in-memory initializer for isolated tests.
- Versioned migrations for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- Repository operations for language/category/set/word CRUD, set movement, membership, duplicate resolution, and global search.
- Global search fetches matching word memberships in batches instead of one database query per result word.
- Set word totals and due-review counts are calculated in SQLite without materializing the full word list.
- Shared words retain a single word-level learning history across sets.
- Library screens support nested categories, uncategorized sets, set detail, word CRUD, import, and moving sets.

### Learning and games
- SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date.
- Flashcards, multiple-choice, typed-answer sessions, due-review queue, weak-word practice, and Mix Sets.
- Pairs, Audio choice (system TTS), Speed typing, and Missing-word games.
- AI Mix Sets selects and orders existing cards from user-selected sets using topic, level, and learning statistics. The user reviews the proposed cards and rationale before choosing flashcards, multiple-choice, or typing practice. Only existing word IDs are accepted; no vocabulary is created, and the shared word-level SRS history is retained.

### Pronunciation
- System text-to-speech reference playback, with US/UK English voice choice.
- Per-word AAC voice recording and playback stored locally under Application Support; the recording directory is excluded from iOS backup.
- Speech recognition compares recognized text with the card's original word and shows transparent text-match feedback; requests require on-device recognition. If the selected locale/device does not support it, recognition does not start and audio is not sent as a fallback. No acoustic score or tone analysis is claimed.
- Chinese cards show pinyin tone hints for tone diacritics and numeric notation (1–5); these are reading aids, not microphone-based tone scoring.

### Import
- Paste text, CSV/TSV/TXT, XLSX with worksheet/column mapping, PDF text extraction, image OCR, and scanned-PDF OCR.
- Imports pass through editable preview, validation, duplicate resolution, and transactional save.

### AI
- Gemini vocabulary generation with editable draft review and explicit save.
- Gemini document extraction converts PDF/text/OCR content into vocabulary and reuses the editable import preview.
- AI enrichment proposes missing transcription, examples, and explanations for an existing set; edits are reviewed before explicit save, and existing word/translation values are preserved.
- AI weak-word analysis considers answer errors, correct/incorrect counts, streak, and review interval. It returns explanations, training recommendations, and a mini exercise for review.
- AI analysis and enrichment do not silently rewrite cards or SRS progress. Gemini API keys are stored in iOS Keychain using `WhenUnlockedThisDeviceOnly` accessibility.
- AI screens now disclose that prompts, document text, card content, and/or learning statistics needed for a request are sent to Google Gemini. The import flow separately warns before document extraction. API keys are not part of the JSON backup model.
- AI Mix Sets recommendations are constrained to supplied candidate IDs; unknown or duplicate IDs and invalid response sizes are rejected.
- Mocked provider tests cover validation and representative successful/error responses.

### Sets tab
- Cross-language set catalogue with per-language grouping, nested category disclosure, uncategorized sets, search by set name or any level of its category path, and sorting by name, creation date, or word count.
- Quick set creation directly from the Sets tab, with language, nested category path, and optional description.
- Direct navigation to set detail and category/library management.

### Profile and learning history
- Seven milestone achievements with live progress and unlock states.
- Daily local notification reminders with an in-app time picker and permission handling.
- Versioned daily activity table, updated atomically with every SRS answer.
- Profile dashboard, monthly activity calendar, study-day totals, reviews, and streaks.

### Backup and export
- JSON backup includes languages, nested categories, sets, words, shared-word memberships, SRS progress, and study activity.
- Restore validates schema and references before replacing the library in a database transaction.
- CSV export includes vocabulary, translations, transcription, notes, and examples, with UTF-8 BOM and correct quoting.

## Known gaps

- Accessibility and Dynamic Type remain partial; finish remaining screens, Voice Control, and contrast review.
- Privacy/network review remains partial: speech recognition is local-only where supported and recordings are excluded from backup, but broader logging, network, temporary-file retention, and deletion behavior still need a source-wide audit.
- Appearance polish, broader performance profiling, and device packaging remain.
- The unsigned device-Release IPA has been built, structurally validated, and uploaded successfully. It is not signed for direct installation; SideStore must re-sign it. Installation and launch on the owner's iPhone remain unverified.
- Speech recognition quality depends on iOS language support and device settings; pinyin tone hints are not acoustic tone scoring.
- AI Mix Sets currently limits a single recommendation request to 3–100 unique cards; larger libraries require narrowing the selected sets.

## Verification policy

GitHub Actions on macos-latest is authoritative because development is performed on Windows without Xcode. A feature is verified only after the iOS Simulator build and XCTest pass.

## Next

Download the verified `LMR-SideStore-unsigned-IPA` artifact from workflow run #45995703782, import it into SideStore, and verify installation and launch on the owner's iPhone. Continue the app-wide accessibility and privacy/network audits.
