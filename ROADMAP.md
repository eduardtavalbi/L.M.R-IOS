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
- [x] First-run onboarding with suggested language selection and skip option.
- [x] Library navigation, nested categories, uncategorized sets, set movement.
- [x] Word creation/editing and global search.
- [x] Search results show all sets containing each word.
- [x] Edit/delete operations and duplicate skip/keep-both/merge flow.
- [x] Cross-language Sets tab with search by set name and nested category path.
- [x] Set sorting by name, newest first, and word count.
- [x] Category-aware Sets browsing, nested category navigation, and direct set creation.

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
- [x] Gemini document vocabulary extraction with source-length validation and editable import preview.
- [x] AI enrichment of existing sets with editable review and explicit save (CI #45974032162).
- [x] AI weak-word analysis with recommendation and mini-exercise preview (CI #45976200195).
- [x] AI Mix Sets from selected existing sets, with review before starting and existing word IDs only (CI #45978494297).

## Phase 6 — Pronunciation
- [x] Reference audio playback and English UK/US variants.
- [x] Voice recording and playback.
- [x] Speech recognition and transparent text-match feedback.
- [x] Chinese pinyin tone hints from diacritics and numeric notation.

## Phase 7 — Progress, profile, and backup
- [x] Basic profile statistics: vocabulary totals, mastered count, review count, and answer accuracy.
- [x] Per-word/per-set performance.
- [x] Persisted daily activity, monthly calendar, study-day count, and current streak.
- [x] Seven milestone achievements with live progress and unlock states.
- [x] Local daily reminders with configurable time and notification permission handling.
- [x] Full local JSON backup/restore with validation and transactional replacement.
- [x] CSV export of vocabulary fields.

## Phase 8 — Quality and delivery
- [ ] Complete app-wide accessibility audit (core Dynamic Type and VoiceOver improvements are implemented and CI-verified in learning, games, onboarding, import, and library flows; remaining screens and Voice Control/contrast still need review).
- [ ] Light/dark appearance polish and performance checks.
- [ ] Complete privacy review (Keychain storage with `WhenUnlockedThisDeviceOnly`, exclusion of API keys from JSON backups, and Gemini data-transfer disclosures implemented; source-wide logging, retention, and network review remains).
- [ ] Apple signing and SideStore-compatible packaging workflow.
- [ ] Verify installation on the owner's iPhone.

## Current next task

Finish the app-wide accessibility audit, then perform a source-wide privacy/network and performance review. Device installation claims remain separate from Simulator CI verification.

## Latest verification

- `7c19156` — Gemini data-processing disclosures; GitHub Actions run #45986246891 passed (iOS Simulator build and XCTest).
- `a736602` — core VoiceOver labels and values; GitHub Actions run #45983308627 passed.
- Dynamic Type changes across core learning, game, onboarding, and import screens passed the associated GitHub Actions runs.
