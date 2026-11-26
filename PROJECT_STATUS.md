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
- Repository operations for language/category/set/word creation, set movement, set membership, and library reads.
- Language consistency validation for repository operations.

### Library UI

- Five-tab SwiftUI navigation shell.
- Local library screen with language list and empty state.
- Nested category navigation and uncategorized sets.
- Create language, category, set, and word flows.
- Move sets between categories or to the uncategorized area.
- Global search across original words, translations, set names, and category names.
- Word search results show every set containing that word and link into each set.

## Verification

- GitHub Actions is the authoritative build/test environment because the owner does not have Xcode locally.
- Run #15 completed successfully: iOS Simulator app build and all 6 XCTest cases passed.
- New changes must be considered unverified until their own GitHub Actions run completes successfully.

## Next

Continue library completeness: edit/delete flows, category-path clarity, duplicate resolution (skip/keep both/merge), and richer word/set membership management. Then build the learning engine.
