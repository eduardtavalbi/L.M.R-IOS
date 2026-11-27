# L.M.R. — Implementation Roadmap

Check off work only after implementation and successful GitHub Actions verification.

## Phase 0 — Repository foundation
- [x] SwiftUI/XcodeGen project skeleton and five-tab navigation.
- [x] GitHub Actions iOS Simulator build and XCTest.

## Phase 1 — Domain model and local persistence
- [x] GRDB-backed SQLite database, migrations, foreign keys, and indexes.
- [x] Language, nested category, vocabulary set, word, membership, and learning progress models.
- [x] Repository CRUD, relationships, shared words, and duplicate policies.
- [x] Isolated persistence and repository tests.

## Phase 2 — Library experience
- [ ] App bootstrap and dependency container.
- [ ] First-run onboarding.
- [x] Library navigation, nested categories, uncategorized sets, set movement.
- [x] Word creation/editing and global search.
- [x] Search results show all sets containing each word.
- [x] Edit/delete operations and duplicate skip/keep-both/merge flow.
- [x] Cross-language Sets tab with search and set-detail navigation.
- [x] Category-aware Sets browsing, nested category navigation, and direct set creation from the Sets tab.

## Phase 3 — Learning engine
- [x] Flashcards and card details.
- [x] Word-level SRS shared across sets.
- [x] Due-review queue and future-review deferral.
- [x] Multiple-choice and typed-answer modes.
- [x] Weak-word practice and Mix Sets.

## Phase 4 — Games
- [x] Pairs matching game.
- [x] Audio choice with system text-to-speech.
- [x] Speed 60-second typing challenge.
- [x] Missing-word sentence completion.
- [x] Games do not modify SRS history.

## Phase 5 — Import and AI
- [x] Paste text pairs with editable preview and validation.
- [x] CSV/TSV/TXT file import.
- [x] XLSX import with worksheet and column mapping.
- [x] PDF text-layer extraction into editable review.
- [x] On-device image OCR and scanned-PDF OCR via Apple Vision.
- [x] Quoted CSV fields, embedded delimiters/newlines, CRLF, and escaped quote handling.
- [x] AI provider abstraction and Keychain-backed API-key storage.
- [x] Gemini vocabulary generation client with JSON parsing and request validation.
- [x] AI screen with secure key setup, generation controls, and editable review.
- [x] Persist generated explanations as notes and keep examples separate.
- [x] Mocked Gemini network tests (success, rate limit, missing key).
- [ ] AI document extraction, enrichment, weak-word analysis, and AI Mix Sets.

## Phase 6 — Pronunciation
- [ ] Reference audio playback and English UK/US variants.
- [ ] Voice recording and playback.
- [ ] Speech recognition and transparent pronunciation feedback.
- [ ] Chinese pinyin and tone support.

## Phase 7 — Progress, profile, and backup
- [x] Basic profile statistics: vocabulary totals, mastered count, review count, and answer accuracy.
- [ ] Per-word/per-set performance.
- [x] Persisted daily activity, monthly calendar, study-day count, and current streak.
- [ ] Restrained achievements and celebrations.
- [ ] Local daily reminders.
- [ ] Full local backup/restore and CSV export.

## Phase 8 — Quality and delivery
- [ ] App accessibility and Dynamic Type.
- [ ] Light/dark appearance polish and performance checks.
- [ ] Privacy review and secret-handling audit.
- [ ] Apple signing and SideStore-compatible packaging workflow.
- [ ] Verify installation on the owner's iPhone.

## Current next task

Continue with per-word/per-set performance, achievements, reminders, and backup/restore. Keep device installation claims separate from Simulator CI verification.
