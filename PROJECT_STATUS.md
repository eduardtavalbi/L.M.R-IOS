# L.M.R. — Project Status

Last updated: 2026-11-26

## Product

**L.M.R. — Learn. Memorize. Repeat.**  
Russian slogan: «Учись. Запоминай. Повторяй.»

A personal, non-commercial, offline-first iOS language-learning app. The current target is a native SwiftUI app for iOS 17+.

## Repository

- Repository: https://github.com/eduardtavalbi/L.M.R-IOS
- Default branch: `main`
- Project generation: XcodeGen (`project.yml`)
- CI: GitHub Actions on `macos-latest`
- Build toolchain: Xcode on GitHub-hosted macOS runners; the owner works from Windows and does not have local Xcode.

## Verified state on GitHub

- Initial repository commit: `78767ec4f2ef7757e933820116bd15b77ba64eff`
- Initial GitHub Actions run: #1, completed successfully.
- What was verified: XcodeGen project generation and iOS Simulator build.
- Unit tests were **not** run by that initial workflow.
- The app currently has a five-tab SwiftUI shell: Library, Learning, Sets, AI, Profile. Most sections are placeholders.
- The remote `main` branch currently contains only the initial project skeleton. It does not yet contain GRDB, database models, or repositories.

## Important local/remote distinction

During the handover, the owner showed local uncommitted work on their Windows machine:
- modified `project.yml`, `.github/workflows/ios-build.yml`, and `Tests/LMRTests.swift`;
- untracked `Core/Database/`, `Core/Models/`, and `Core/Repositories/`.

That work had not been pushed to GitHub at the time of inspection. Do not assume it exists on the remote branch. Reconstruct/review and integrate it deliberately; do not tell the owner to discard it and do not overwrite their local checkout blindly.

## Approved product decisions

- Personal pet project, not intended for commercial launch.
- Offline-first; no registration, account, or backend for the core app.
- Native Swift + SwiftUI.
- Local persistence with SQLite through GRDB.
- Bottom navigation: Главная (library), Обучение, Наборы, AI, Профиль.
- Main screen is the library, not a dashboard.
- Any source/target language pair; start with Chinese and English as common examples.
- User-created unlimited nested categories under a language; sets may be uncategorized and movable.
- Global library search across words, translations, set titles, and categories. Word results show all sets containing the word.
- One word can belong to multiple sets; learning progress is shared at word level.
- Duplicate handling should offer skip, keep both, or merge information.
- Learning modes: flashcards, multiple choice, typing, audio.
- Games: pairs, audio, speed, missing-word-in-sentence.
- SRS review, weak words, set training, Mix Sets.
- Cards: foreign word on front; translation plus transcription/pinyin on back; optional extra details separately.
- Import: manual entry, pasted pairs, CSV, Excel, PDF/TXT/documents, photos/OCR, and AI-assisted generation; preview/edit before saving.
- AI provider abstraction; user-supplied keys stored in Keychain. Never commit API keys or secrets.
- Pronunciation: reference audio, own recording, comparison/hints; do not claim precise phonetic scoring from speech recognition alone.
- Statistics: added/studied/mastered words, accuracy, repetitions/errors, streaks, activity calendar, restrained achievements.
- Optional local reminders.
- Optional manual backup/export; no cloud account or sync in the first version.
- Visual direction: premium minimal, native iOS, light/dark mode, subtle gamification, restrained congratulations.

## Engineering rules

1. Work against the actual remote repository state; fetch/read files before editing.
2. Use focused, logically complete commits with conventional messages.
3. Never force-push or rewrite existing history.
4. Do not commit secrets, signing credentials, provisioning profiles, or personal data.
5. Run the strongest available automated checks before claiming success.
6. GitHub Actions build success and XCTest success must be reported separately.
7. Do not claim an app is installable on the owner's iPhone until a signing/export/install path has been implemented and verified.
8. Keep this file and `ROADMAP.md` updated at meaningful milestones.
9. The owner uses Windows 11 and VS Code; use GitHub-hosted macOS runners for Xcode builds/tests. Do not require local Xcode.
10. The owner prefers substantial, coherent implementation batches over repetitive one-file-at-a-time instructions.
