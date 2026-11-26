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
- Pairs game: run #33 succeeded.
- Audio choice: run #34 succeeded.
- Speed game: run #36 succeeded.
- Missing word in sentence: run #38 succeeded on commit f8866b60b8b92dd2754ce888ce04ec4fb697acc4.
- Text-pair import parser and editable preview: run #43 succeeded.
- CSV/TXT file picker and import flow: run #44 succeeded; both iOS Simulator build and XCTest passed.

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
- Missing: translation-guided sentence completion, answer normalization, score, progress, and restart. Eligible cards require an example containing the target word. It does not update SRS.

### Import

- Paste tab-, comma-, or semicolon-delimited word pairs.
- Parse preview with editable original, translation, transcription, and example fields.
- Required-field validation and duplicate resolution (skip, keep both, merge).
- Transactional batch import into a selected vocabulary set.
- CSV, TSV, and plain-text file selection with UTF-8, UTF-16, and Windows-1251 decoding fallback.
- Import repository tests cover metadata, duplicate policies, transaction rollback, and missing target sets.
- XLSX, PDF, and image OCR are not implemented yet.

## Verification

GitHub Actions on macos-latest is authoritative because the owner develops on Windows and has no local Xcode. Every feature is expected to pass an iOS Simulator build and XCTest before being marked complete.

## Next

Add XLSX spreadsheet import with worksheet selection/mapping, then PDF text extraction and image OCR through a reviewable import pipeline.
