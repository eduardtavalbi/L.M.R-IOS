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

- Full build and XCTest verification: run #15 succeeded.
- Learning modes and SRS baseline: run #28 succeeded.
- Weak-word and Mix Sets integration: run #32 succeeded; iOS Simulator build and all 22 XCTest cases passed.
- Pairs game: run #33 succeeded on commit 036c77f147f5a1e8853be97149c0f46f1bc5bab8.
- Audio choice: run #34 succeeded on commit 2378a55d1fd6a4c59ab12f11a1387bcebafacd58.
- Speed game: run #36 succeeded on commit 5b5d47b72610407b48a7541d38edff705c374f8e; iOS Simulator build and XCTest passed.

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

### Games

- Pairs: shuffled word/translation matching, feedback, move counter, completion, and restart. It does not update SRS.
- Audio choice: system text-to-speech prompts, randomized translation choices, score, and replay. Voice availability depends on iOS language assets. It does not update SRS.
- Speed: 60-second translation typing challenge, streak bonuses, score, skip, and restart. It does not update SRS.
- Missing word in sentence is the next game under implementation.

## Verification

GitHub Actions on macos-latest is authoritative because the owner develops on Windows and has no local Xcode. Every feature is expected to pass an iOS Simulator build and XCTest before being marked complete.

## Next

Implement Missing word in sentence, then continue with import flows and the remaining product roadmap.
