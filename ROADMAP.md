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
- [x] First-run onboarding with suggested language selection and skip option (CI #96).
- [x] Library navigation, nested categories, uncategorized sets, set movement.
- [x] Word creation/editing and global search.
- [x] Search results show all sets containing each word.
- [x] Edit/delete operations and duplicate skip/keep-both/merge flow.
- [x] Cross-language Sets tab with search by set name and nested category path, category-location labels, and set-detail navigation (CI #99 green).
- [x] Set sorting by name, newest first, and word count across uncategorized and nested-category groups (CI #97; cached word counts CI #98).
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
- [x] Gemini document vocabulary extraction with source-length validation, duplicate filtering, and editable import preview.\n- [ ] AI document enrichment, weak-word analysis, and AI Mix Sets.

## Phase 6 — Pronunciation
- [x] Reference audio playback and English UK/US variants.
- [x] Voice recording and playback.
- [x] Speech recognition and transparent text-match feedback (CI #92).
- [x] Chinese pinyin tone hints from diacritics and numeric notation (CI #94).

## Phase 7 — Progress, profile, and backup
- [x] Basic profile statistics: vocabulary totals, mastered count, review count, and answer accuracy.
- [x] Per-word/per-set performance (review/error counters and accuracy).
- [x] Persisted daily activity, monthly calendar, study-day count, and current streak.
- [x] Seven milestone achievements with live progress and unlock states.
- [x] Local daily reminders with configurable time and notification permission handling.
- [x] Full local JSON backup/restore with validation and transactional replacement (CI #86 green).
- [x] CSV export of vocabulary fields (CI #89 green).

## Phase 8 — Quality and delivery
- [ ] App accessibility and Dynamic Type.
- [ ] Light/dark appearance polish and performance checks.
- [ ] Privacy review and secret-handling audit.
- [ ] Apple signing and SideStore-compatible packaging workflow.
- [ ] Verify installation on the owner's iPhone.

## Current next task

Continue AI document enrichment, weak-word analysis, and AI Mix Sets. Keep pinyin tone hints distinct from speech-recognition scoring; do not claim acoustic tone assessment. Device installation claims remain separate from Simulator CI verification.
