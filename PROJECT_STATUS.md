# L.M.R. — Project Status

Last updated: 2026-11-26

## Product

**L.M.R. — Learn. Memorize. Repeat.**  
Russian slogan: «Учись. Запоминай. Повторяй.»

A personal, non-commercial, offline-first iOS language-learning app. Native SwiftUI, iOS 17+.

## Repository and delivery

- Repository: https://github.com/eduardtavalbi/L.M.R-IOS
- Working branch: main
- Project generation: XcodeGen (project.yml)
- CI: GitHub Actions on macos-latest
- Development machine: Windows 11; all Xcode builds and XCTest run in GitHub Actions.

## Verified remote baseline

- Initial commit: 78767ec4f2ef7757e933820116bd15b77ba64eff.
- Initial iOS Simulator build: GitHub Actions run #1 succeeded.
- Full build and XCTest verification: run #15 succeeded on commit de338c2d1afc61f2097a7b131e7e05b1d91ecfe6.
- The previous chat's unpushed local changes were not present on GitHub and were not overwritten.

## Current implementation

### Persistence and repository

- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite.
- In-memory database initializer for isolated tests.
- Versioned migration for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- SQLite foreign keys, cascade/set-null behavior, and lookup indexes.
- Repository operations for language/category/set/word creation, editing/deletion, set movement, set membership, and library reads.
- Duplicate detection is language-scoped and compares normalized original text plus translation; users can skip, keep both, or merge by linking the existing word to the current set.
- Word-level SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date; progress is shared across sets.
- Basic flashcard sessions support reveal, "Знаю", and "Повторить", with a session summary.
- Language consistency validation for repository operations.

### Library UI

- Five-tab SwiftUI navigation shell with a working Learning tab.
- Local library screen with language list and empty state.
- Nested category navigation and uncategorized sets.
- Create, edit, and delete language, category, set, and word flows with confirmation for destructive actions.
- Duplicate-word detection with skip, keep-both, and merge choices.
- Move sets between categories or to the uncategorized area.
- Global search across original words, translations, set names, and category names.
- Word search results show every set containing that word and link into each set.

## Verification

- GitHub Actions is the authoritative build/test environment because the owner does not have Xcode locally.
- Run #20 completed successfully: iOS Simulator app build and all 10 XCTest cases passed.
- New changes must be considered unverified until their own GitHub Actions run completes successfully.

## Next

Expand learning beyond flashcards: multiple-choice and typing sessions, due-review queue, weak-word practice, and Mix Sets.
