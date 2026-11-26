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
- Pairs game: run #33 succeeded on commit 036c77f147f5a1e8853be97149c0f46f1bc5bab8; build and tests passed.

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
- Pairs is a matching game with shuffled word/translation cards, feedback, move counter, completion, and restart. It does not update SRS because matching is recognition practice.
- Audio choice is implemented with system text-to-speech, spoken prompts, randomized translation choices, score, and replay. It does not update SRS; audio voices depend on the language code and voices available on the device.
- Global library search covers original words, translations, set names, and category names; word results include all containing sets.

### Verification

- GitHub Actions is authoritative because the owner does not have Xcode locally.
- Run #32 succeeded with weak-word and multi-set query coverage.
- Run #33 succeeded: Pairs app integration and four PairsGameEngine tests passed.

## Next

Audio choice is implemented in the current branch and awaiting CI verification. Next game after a green run: Speed.
