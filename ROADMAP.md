# L.M.R. — Implementation Roadmap

This roadmap is a living plan. Check off only work that has actually been implemented and verified.

## Phase 0 — Repository foundation

- [x] Create repository and initial SwiftUI/XcodeGen project skeleton.
- [x] Add five-tab navigation shell.
- [x] Verify first GitHub Actions iOS Simulator build.
- [x] Add durable project status and roadmap tracking.
- [x] Configure CI to build and run XCTest.

## Phase 1 — Domain model and local persistence

- [x] Integrate GRDB through XcodeGen Swift Package dependency.
- [x] Implement persistent SQLite database in Application Support.
- [x] Add database migrations and foreign-key enforcement.
- [x] Implement Language, Category, VocabularySet, Word, and LearningProgress models.
- [x] Implement repository operations and validation for language/category relationships.
- [x] Support nested categories, uncategorized sets, moving sets, and words shared by multiple sets.
- [x] Add isolated XCTest coverage for migrations, persistence, relationships, and repository behavior.
- [x] Verify build and tests in GitHub Actions (run #15).

## Phase 2 — Library experience

- [ ] App bootstrap and dependency container.
- [ ] First-run onboarding: welcome, appearance, language, first set.
- [x] Library screen and empty states.
- [x] Language and category navigation, including nested categories.
- [x] Create vocabulary sets and move them between categories.
- [x] Create vocabulary words with translation and transcription.
- [x] Global search across original words, translations, set names, and categories.
- [x] Show all sets containing a matching word.
- [x] Edit/delete language, category, set, and word.
- [x] Duplicate detection and skip/keep-both/merge flow.

## Phase 3 — Learning engine

- [x] Card presentation and details.
- [x] Basic flashcard session with reveal, "Знаю", and "Повторить" actions.
- [x] Word-level progress shared across sets.
- [x] Basic SRS scheduling with 1-day, 3-day, ease-adjusted intervals and 10-minute relearning for forgotten words.
- [x] Due-review queue: new words and due reviews are included; future-due reviews are deferred (run #27).
- [x] Multiple-choice learning mode (run #28).
- [x] Typing learning mode (run #28).
- [x] Weak-word and multi-set repository queries, deduplicated by word ID.
- [x] Weak-word practice and Mix Sets UI, with flashcard, multiple-choice, and typing sessions (run #32).

## Phase 4 — Games

- [x] Pairs game: shuffled word/translation cards, matching feedback, move counter, completion and restart (run #33).
- [x] Audio choice: spoken prompt, translation choices, score and replay (run #34).
- [ ] Speed.
- [ ] Missing word in sentence.
- [x] Games do not alter SRS unless a game explicitly provides a reliable recall result; Pairs and Audio choice are recognition games.

## Phase 5 — Import and AI

- [ ] Paste/import text pairs.
- [ ] CSV import/export.
- [ ] XLSX and document import.
- [ ] PDF and image OCR pipeline with review screen.
- [ ] AI provider abstraction and Keychain-backed API key storage.
- [ ] AI vocabulary generation, enrichment, and document-to-cards flow.
- [ ] AI Mix Sets and learning assistance.

## Phase 6 — Pronunciation

- [ ] Reference audio playback.
- [ ] Voice recording and playback.
- [ ] Speech recognition integration.
- [ ] Pronunciation feedback with clearly stated accuracy limitations.
- [ ] English UK/US pronunciation choice; Chinese pinyin and tones.

## Phase 7 — Progress, profile, and backup

- [ ] Statistics and per-word/per-set performance.
- [ ] Activity calendar, streaks, and history.
- [ ] Restrained achievements and celebrations.
- [ ] Local daily reminders.
- [ ] Full local backup and restore.
- [ ] CSV export.

## Phase 8 — Quality and delivery

- [ ] Accessibility and Dynamic Type.
- [ ] Light/dark mode polish.
- [ ] Performance and database migration checks.
- [ ] Privacy review; ensure secrets never enter source control.
- [ ] Decide on Apple signing and a safe SideStore-compatible installation workflow.
- [ ] Verify installation on the owner's iPhone before calling the app device-ready.

## Current next task

Implement Speed game.
