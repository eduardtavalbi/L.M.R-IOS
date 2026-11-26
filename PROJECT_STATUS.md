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
- Previous unpushed local changes were not present on GitHub and were not overwritten.
- Latest verified learning baseline: run #27 succeeded on commit a7222f8c4a420853e67f6272c2f76eb774571d23; iOS Simulator build and XCTest job both passed.

## Current implementation

### Persistence and repository

- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite.
- In-memory database initializer for isolated tests.
- Versioned migration for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- SQLite foreign keys, cascade/set-null behavior, and lookup indexes.
- Repository operations for language/category/set/word creation, editing/deletion, set movement, set membership, and library reads.
- Duplicate detection is language-scoped and compares normalized original text plus translation; users can skip, keep both, or merge by linking the existing word to the current set.
- Word-level SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date; progress is shared across sets.
- Flashcard sessions support reveal, "Знаю", and "Повторить", with a session summary.
- The active learning queue includes new words and reviews due now; future-scheduled reviews are held back until their due date.
- Global library search covers original words, translations, set names, and category names; word results include all containing sets.

### Verification

- GitHub Actions is authoritative because the owner does not have Xcode locally.
- Run #23 succeeded: iOS Simulator build and 14 XCTest cases passed.
- Run #24 exposed an incorrect due-queue test fixture; commit 0104c8d corrected its review timestamp.
- Run #27 succeeded after the correction and after retaining the SQL due-date filter.

## Next

Add multiple-choice and typing learning modes, then weak-word practice and Mix Sets. All learning modes must share the same word-level SRS progress.
