# L.M.R. — Implementation Roadmap

This roadmap is a living plan. Update checkboxes and notes when work is completed or priorities change.

## Phase 0 — Repository foundation

- [x] Create repository and initial SwiftUI/XcodeGen project skeleton.
- [x] Add five-tab navigation shell.
- [x] Verify first GitHub Actions iOS Simulator build.
- [ ] Add durable project status and roadmap tracking.
- [ ] Establish reliable build + XCTest CI.

## Phase 1 — Domain model and local persistence

- [ ] Integrate GRDB through XcodeGen Swift Package dependency.
- [ ] Implement persistent SQLite database in Application Support.
- [ ] Add database migrations and foreign-key enforcement.
- [ ] Implement Language, Category, VocabularySet, Word, and LearningProgress models.
- [ ] Implement repository operations and validation for language/category relationships.
- [ ] Support nested categories, uncategorized sets, moving sets, and words shared by multiple sets.
- [ ] Add isolated XCTest coverage for migrations, persistence, relationships, and repository behavior.
- [ ] Verify build and tests in GitHub Actions.

## Phase 2 — Library experience

- [ ] App bootstrap and dependency container.
- [ ] First-run onboarding: welcome, appearance, language, first set.
- [ ] Library screen and empty states.
- [ ] Language and category management, including nested navigation.
- [ ] Vocabulary set list, create/edit/move/delete.
- [ ] Word creation/editing and set membership.
- [ ] Global search across words, translations, sets, and categories.
- [ ] Duplicate detection and skip/keep-both/merge flow.

## Phase 3 — Learning engine

- [ ] Card presentation and details.
- [ ] Flashcard, multiple-choice, typing, and audio sessions.
- [ ] Word-level progress shared across sets.
- [ ] SRS scheduling and due-review queue.
- [ ] Weak-word and selected-set training.
- [ ] Mix Sets.

## Phase 4 — Games

- [ ] Pairs.
- [ ] Audio choice.
- [ ] Speed.
- [ ] Missing word in sentence.
- [ ] Explicit rules for whether a game result affects SRS.

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

Recover/review the owner's unpushed local GRDB draft from the handover conversation, integrate it cleanly into a feature branch or a focused commit, then run the iOS build and XCTest in GitHub Actions. The current remote `main` does not contain that draft.
