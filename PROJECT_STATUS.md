# L.M.R. — Project Status

Last updated: 2026-11-26

## Product

**L.M.R. — Learn. Memorize. Repeat.**  
Russian slogan: «Учись. Запоминай. Повторяй.»

A personal, non-commercial, offline-first iOS language-learning app. Native SwiftUI, iOS 17+.

## Repository and delivery

- Repository: https://github.com/eduardtavalbi/L.M.R-IOS
- Working branch: `main`
- Project generation: XcodeGen (`project.yml`)
- CI: GitHub Actions on `macos-latest`
- Development machine: Windows 11; all Xcode builds and XCTest run in GitHub Actions.

## Verified remote baseline

- Initial commit: `78767ec4f2ef7757e933820116bd15b77ba64eff`.
- Initial iOS Simulator build: GitHub Actions run #1 succeeded.
- The initial workflow did not run XCTest.
- The previous chat's unpushed local changes were not present on GitHub and were not overwritten.

## Current implementation

### Completed in this milestone — local persistence foundation

- Added GRDB.swift 7 as an XcodeGen Swift Package dependency.
- Added persistent SQLite storage under Application Support/LMR/library.sqlite.
- Added an in-memory database initializer for isolated tests.
- Added versioned migration for languages, nested categories, vocabulary sets, words, set membership, and word-level learning progress.
- Enabled SQLite foreign keys and appropriate cascade/set-null behavior.
- Added indexes for library lookups and due-review scheduling.
- Added repository operations for language/category/set/word creation, set movement, set membership, and library reads.
- Enforced language consistency in repository operations.
- Added XCTest coverage for nested categories, uncategorized/movable sets, shared words/progress, invalid cross-language links, and database reopening.
- Updated CI to run both simulator build and XCTest.

## Verification

- GitHub Actions is the authoritative build/test environment because the owner does not have Xcode locally.
- Do not report build or test success until the new workflow run completes successfully.
- The initial baseline run only verified project generation and simulator compilation; it did not execute tests.

## Next

After CI validation, continue with the library experience: app dependency container, onboarding, language/category/set management screens, word editor, and global search. Duplicate resolution (skip/keep both/merge) belongs in the import/word-entry flow.
