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
- Learning modes and SRS baseline: run #28 succeeded on commit faca40a73e5beed23a57f09ba6841123ac2f7e98.
- Latest learning integration: GitHub Actions run #32 succeeded on commit 87e47be9946c0276becf1cabac9581243759e626; iOS Simulator build and all 22 XCTest cases passed.

## Current implementation

### Persistence and repository

- GRDB.swift 7 with SQLite storage under Application Support/LMR/library.sqlite.
- In-memory database initializer for isolated tests.
- Versioned migration for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- SQLite foreign keys, cascade/set-null behavior, and lookup indexes.
- Repository operations for language/category/set/word creation, editing/deletion, set movement, set membership, and library reads.
- Duplicate detection is language-scoped and compares normalized original text plus translation; users can skip, keep both, or merge by linking the existing word to the current set.
- Word-level SRS progress persists correct/incorrect answers, streak, interval, ease factor, and next due date; progress is shared across sets.
- Flashcard sessions support reveal, "Знаю", and "Повторить"; multiple-choice and typing modes use the same SRS answer recording.
- The active learning queue includes new words and reviews due now; future-scheduled reviews are held back until their due date.
- Multi-set learning combines selected sets without duplicate shared words. Weak-word practice includes words with recorded mistakes, even when their next review is in the future.
- Learning UI exposes per-set sessions, weak-word practice, and Mix Sets; each supports flashcards, multiple choice, and typing.
- Global library search covers original words, translations, set names, and category names; word results include all containing sets.

### Verification

- GitHub Actions is authoritative because the owner does not have Xcode locally.
- Run #23 succeeded: iOS Simulator build and 14 XCTest cases passed.
- Run #27 succeeded after correcting the due-queue fixture and retaining the SQL due-date filter.
- Run #28 succeeded with multiple-choice and typing modes.
- Run #32 succeeded: iOS Simulator build and 22 XCTest cases passed, including weak-word and multi-set query coverage.

## Next

Pairs game is implemented in the current branch and awaiting CI verification. Games do not alter SRS unless a game explicitly provides a reliable recall result; Pairs is recognition/matching practice and does not update SRS.
