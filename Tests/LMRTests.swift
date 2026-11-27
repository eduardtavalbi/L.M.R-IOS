import XCTest
@testable import LMR

final class LMRTests: XCTestCase {
    func testAppInformation() {
        XCTAssertEqual(AppInfo.name, "L.M.R.")
        XCTAssertEqual(AppInfo.fullName, "Learn. Memorize. Repeat.")
    }

    func testLanguageCategoryAndNestedCategoryPersistence() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let parent = try repository.createCategory(languageID: language.id, name: "Food")
        let child = try repository.createCategory(languageID: language.id, name: "Fruit", parentID: parent.id)
        let fetched = try repository.fetchCategories(languageID: language.id)
        XCTAssertEqual(fetched.map(\.id), [parent.id, child.id])
        XCTAssertEqual(fetched.map(\.name), ["Food", "Fruit"])
        XCTAssertNil(fetched[0].parentID)
        XCTAssertEqual(fetched[1].parentID, parent.id)
        XCTAssertTrue(fetched.allSatisfy { $0.languageID == language.id })
    }

    func testSetCreationPersistsOptionalDetailsAndCategory() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Chinese")
        let category = try repository.createCategory(languageID: language.id, name: "Travel")
        let set = try repository.createSet(
            languageID: language.id,
            name: "At the airport",
            categoryID: category.id,
            details: "Useful airport vocabulary"
        )

        let fetched = try repository.fetchSets(languageID: language.id, categoryID: category.id)
        XCTAssertEqual(fetched.first?.id, set.id)
        XCTAssertEqual(fetched.first?.details, "Useful airport vocabulary")
    }

    func testUncategorizedSetAndMovingBetweenCategories() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "English")
        let first = try repository.createCategory(languageID: language.id, name: "Travel")
        let second = try repository.createCategory(languageID: language.id, name: "Work")
        let set = try repository.createSet(languageID: language.id, name: "Phrases")
        let uncategorized = try repository.fetchSets(languageID: language.id)
        XCTAssertEqual(uncategorized.map(\.id), [set.id])
        XCTAssertNil(uncategorized.first?.categoryID)
        try repository.moveSet(set.id, toCategory: first.id)
        let inFirst = try repository.fetchSets(languageID: language.id, categoryID: first.id)
        XCTAssertEqual(inFirst.first?.id, set.id)
        XCTAssertEqual(inFirst.first?.categoryID, first.id)
        try repository.moveSet(set.id, toCategory: second.id)
        let inSecond = try repository.fetchSets(languageID: language.id, categoryID: second.id)
        XCTAssertEqual(inSecond.first?.id, set.id)
        XCTAssertEqual(inSecond.first?.categoryID, second.id)
    }

    func testWordCanBelongToMultipleSetsAndSharesProgress() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let firstSet = try repository.createSet(languageID: language.id, name: "Food")
        let secondSet = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(languageID: language.id, text: "苹果", translation: "яблоко", transcription: "píngguǒ", inSet: firstSet.id)
        try repository.addWord(word.id, toSet: secondSet.id)
        XCTAssertEqual(try repository.fetchWords(inSet: firstSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchWords(inSet: secondSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
        XCTAssertEqual(try repository.fetchSets(containing: word.id).count, 2)
    }

    func testRejectsCrossLanguageCategoryAndSetMembership() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let chinese = try repository.createLanguage(name: "Chinese")
        let english = try repository.createLanguage(name: "English")
        let category = try repository.createCategory(languageID: chinese.id, name: "Food")
        let englishSet = try repository.createSet(languageID: english.id, name: "Food")
        XCTAssertThrowsError(try repository.createSet(languageID: english.id, name: "Invalid", categoryID: category.id)) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .categoryLanguageMismatch)
        }
        let chineseWord = try repository.createWord(languageID: chinese.id, text: "你好", translation: "hello")
        XCTAssertThrowsError(try repository.addWord(chineseWord.id, toSet: englishSet.id)) { error in
            XCTAssertEqual(error as? LibraryRepositoryError, .setLanguageMismatch)
        }
    }

    func testDatabaseSurvivesReopening() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("library.sqlite")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let languageID: String
        do {
            let database = try DatabaseManager(path: url.path)
            let repository = LibraryRepository(database: database)
            languageID = try repository.createLanguage(name: "Japanese", code: "ja").id
        }
        let reopened = try DatabaseManager(path: url.path)
        let languages = try LibraryRepository(database: reopened).fetchLanguages()
        XCTAssertEqual(languages.map(\.id), [languageID])
    }

    func testGlobalSearchFindsWordsTranslationsSetsAndCategories() throws {
        let database = try DatabaseManager.inMemory()
        let repository = LibraryRepository(database: database)
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let category = try repository.createCategory(languageID: language.id, name: "Food and drinks")
        let foodSet = try repository.createSet(languageID: language.id, name: "Breakfast", categoryID: category.id)
        let dailySet = try repository.createSet(languageID: language.id, name: "Daily phrases")
        let word = try repository.createWord(
            languageID: language.id,
            text: "苹果",
            translation: "green apple",
            transcription: "píngguǒ",
            inSet: foodSet.id
        )
        try repository.addWord(word.id, toSet: dailySet.id)

        let byOriginal = try repository.searchLibrary("苹果")
        XCTAssertEqual(byOriginal.words.map(\.word.id), [word.id])
        XCTAssertEqual(Set(byOriginal.words[0].sets.map(\.id)), Set([foodSet.id, dailySet.id]))
        let byTranslation = try repository.searchLibrary("GREEN")
        XCTAssertEqual(byTranslation.words.map(\.word.id), [word.id])
        let bySetName = try repository.searchLibrary("break")
        XCTAssertEqual(bySetName.sets.map(\.id), [foodSet.id])
        let byCategoryName = try repository.searchLibrary("drinks")
        XCTAssertEqual(byCategoryName.categories.map(\.id), [category.id])
        XCTAssertTrue(try repository.searchLibrary("   ").isEmpty)
    }

    func testDuplicateDetectionMatchesNormalizedOriginalAndTranslationTogether() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let otherLanguage = try repository.createLanguage(name: "Spanish")
        let existing = try repository.createWord(languageID: language.id, text: "  Ice   Cream ", translation: "Мороженое")

        let duplicate = try repository.findDuplicateWord(languageID: language.id, text: "ice cream", translation: "мороженое")
        XCTAssertEqual(duplicate?.id, existing.id)
        XCTAssertNil(try repository.findDuplicateWord(languageID: language.id, text: "Gelato", translation: "Мороженое"))
        XCTAssertNil(try repository.findDuplicateWord(languageID: otherLanguage.id, text: "Ice Cream", translation: "Мороженое"))
    }

    func testMergingDuplicateAddsExistingWordToSetAndPreservesSharedProgress() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let firstSet = try repository.createSet(languageID: language.id, name: "Food")
        let secondSet = try repository.createSet(languageID: language.id, name: "Daily")
        let existing = try repository.createWord(languageID: language.id, text: "苹果", translation: "яблоко", inSet: firstSet.id)
        let progressBefore = try repository.fetchProgress(for: existing.id)

        let duplicate = try repository.findDuplicateWord(languageID: language.id, text: " 苹果 ", translation: " ЯБЛОКО ")
        XCTAssertEqual(duplicate?.id, existing.id)
        try repository.addWord(existing.id, toSet: secondSet.id)

        XCTAssertEqual(try repository.fetchWords(inSet: firstSet.id).map(\.id), [existing.id])
        XCTAssertEqual(try repository.fetchWords(inSet: secondSet.id).map(\.id), [existing.id])
        XCTAssertEqual(try repository.fetchProgress(for: existing.id), progressBefore)
        XCTAssertEqual(try repository.fetchSets(containing: existing.id).count, 2)
    }

    func testSpacedRepetitionSchedulesKnownAndUnknownAnswers() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let initial = LearningProgress(wordID: "word")
        let first = SpacedRepetitionScheduler.applying(knewAnswer: true, to: initial, reviewedAt: start)
        XCTAssertEqual(first.intervalDays, 1)
        XCTAssertEqual(first.streak, 1)
        XCTAssertEqual(first.correctAnswers, 1)
        XCTAssertEqual(first.dueAt, Calendar.current.date(byAdding: .day, value: 1, to: start))
        let second = SpacedRepetitionScheduler.applying(knewAnswer: true, to: first, reviewedAt: start)
        XCTAssertEqual(second.intervalDays, 3)
        XCTAssertEqual(second.streak, 2)
        let forgotten = SpacedRepetitionScheduler.applying(knewAnswer: false, to: second, reviewedAt: start)
        XCTAssertEqual(forgotten.intervalDays, 0)
        XCTAssertEqual(forgotten.streak, 0)
        XCTAssertEqual(forgotten.repetitions, 0)
        XCTAssertEqual(forgotten.incorrectAnswers, 1)
        XCTAssertEqual(forgotten.dueAt, start.addingTimeInterval(600))
    }

    func testLearningQueueIncludesNewAndDueWordsButExcludesFutureReviews() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Queue")
        let newWord = try repository.createWord(languageID: language.id, text: "new", translation: "новый", inSet: set.id)
        let dueWord = try repository.createWord(languageID: language.id, text: "due", translation: "пора", inSet: set.id)
        let futureWord = try repository.createWord(languageID: language.id, text: "future", translation: "позже", inSet: set.id)
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        // A forgotten card reviewed 700 seconds earlier is already overdue.
        try repository.recordLearningAnswer(wordID: dueWord.id, knewAnswer: false, reviewedAt: start.addingTimeInterval(-700))
        // A known card reviewed now is scheduled for tomorrow and must stay hidden.
        try repository.recordLearningAnswer(wordID: futureWord.id, knewAnswer: true, reviewedAt: start)

        let beforeDue = try repository.fetchLearningQueue(inSet: set.id, dueAt: start.addingTimeInterval(300))
        XCTAssertEqual(Set(beforeDue.map(\.id)), Set([newWord.id, dueWord.id]))

        let afterDue = try repository.fetchLearningQueue(inSet: set.id, dueAt: start.addingTimeInterval(700))
        XCTAssertEqual(Set(afterDue.map(\.id)), Set([newWord.id, dueWord.id]))
        XCTAssertFalse(afterDue.contains { $0.id == futureWord.id })
    }

    func testReviewProgressPersistsAndIsSharedAcrossSets() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let firstSet = try repository.createSet(languageID: language.id, name: "First")
        let secondSet = try repository.createSet(languageID: language.id, name: "Second")
        let word = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: firstSet.id)
        try repository.addWord(word.id, toSet: secondSet.id)
        let reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        try repository.recordLearningAnswer(wordID: word.id, knewAnswer: true, reviewedAt: reviewedAt)
        let progress = try XCTUnwrap(repository.fetchProgress(for: word.id))
        XCTAssertEqual(progress.correctAnswers, 1)
        XCTAssertEqual(progress.intervalDays, 1)
        XCTAssertEqual(try repository.fetchWords(inSet: secondSet.id).first?.id, word.id)
    }

    func testLibraryEntitiesCanBeEdited() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Chinese", code: "zh")
        let category = try repository.createCategory(languageID: language.id, name: "Food")
        let set = try repository.createSet(languageID: language.id, name: "Breakfast", categoryID: category.id)
        let word = try repository.createWord(languageID: language.id, text: "苹果", translation: "apple", inSet: set.id)

        try repository.updateLanguage(language.id, name: "Mandarin", code: "cmn")
        try repository.updateCategory(category.id, name: "Meals")
        try repository.updateSet(set.id, name: "Morning food", details: "Useful words")
        try repository.updateWord(word.id, text: "香蕉", translation: "banana", transcription: "xiāngjiāo")

        XCTAssertEqual(try repository.fetchLanguage(id: language.id)?.name, "Mandarin")
        XCTAssertEqual(try repository.fetchLanguage(id: language.id)?.code, "cmn")
        XCTAssertEqual(try repository.fetchCategories(languageID: language.id).first?.name, "Meals")
        XCTAssertEqual(try repository.fetchSets(languageID: language.id, categoryID: category.id).first?.name, "Morning food")
        let updatedWord = try repository.fetchWords(inSet: set.id).first
        XCTAssertEqual(updatedWord?.text, "香蕉")
        XCTAssertEqual(updatedWord?.translation, "banana")
        XCTAssertEqual(updatedWord?.transcription, "xiāngjiāo")
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
    }

    func testDeletingCategoryPreservesSetsAndDeletingSetPreservesSharedWords() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let category = try repository.createCategory(languageID: language.id, name: "Work")
        let set = try repository.createSet(languageID: language.id, name: "Meetings", categoryID: category.id)
        let otherSet = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: set.id)
        try repository.addWord(word.id, toSet: otherSet.id)

        try repository.deleteCategory(category.id)
        XCTAssertTrue(try repository.fetchCategories(languageID: language.id).isEmpty)
        XCTAssertNil(try repository.fetchSets(languageID: language.id, categoryID: set.categoryID).first)
        XCTAssertEqual(Set(try repository.fetchSets(languageID: language.id).map(\.id)), Set([set.id, otherSet.id]))
        XCTAssertNil(try repository.fetchSets(containing: word.id).first(where: { $0.id == set.id })?.categoryID)

        try repository.deleteSet(set.id)
        XCTAssertEqual(try repository.fetchWords(inSet: otherSet.id).map(\.id), [word.id])
        XCTAssertEqual(try repository.fetchProgress(for: word.id)?.wordID, word.id)
    }

    func testDeletingWordRemovesMembershipAndProgressButDeletingLanguageCascades() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Japanese")
        let set = try repository.createSet(languageID: language.id, name: "Basics")
        let word = try repository.createWord(languageID: language.id, text: "水", translation: "вода", inSet: set.id)
        try repository.deleteWord(word.id)
        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
        XCTAssertNil(try repository.fetchProgress(for: word.id))

        let anotherWord = try repository.createWord(languageID: language.id, text: "火", translation: "огонь", inSet: set.id)
        try repository.deleteLanguage(language.id)
        XCTAssertNil(try repository.fetchLanguage(id: language.id))
        XCTAssertTrue(try repository.fetchWords(inSet: set.id).isEmpty)
        XCTAssertNil(try repository.fetchProgress(for: anotherWord.id))
    }


    func testStudyActivityAggregatesReviewsAndCountsFirstReviewOnce() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Daily")
        let word = try repository.createWord(languageID: language.id, text: "hello", translation: "привет", inSet: set.id)
        let day = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 12)))
        try repository.recordLearningAnswer(wordID: word.id, knewAnswer: true, reviewedAt: day)
        try repository.recordLearningAnswer(wordID: word.id, knewAnswer: false, reviewedAt: day.addingTimeInterval(3600))
        try repository.recordLearningAnswer(wordID: word.id, knewAnswer: true, reviewedAt: day.addingTimeInterval(7200))
        let stats = try repository.fetchLearningStatistics(for: day, now: day.addingTimeInterval(7200))
        XCTAssertEqual(stats.totalWords, 1)
        XCTAssertEqual(stats.totalReviews, 3)
        XCTAssertEqual(stats.correctAnswers, 2)
        XCTAssertEqual(stats.incorrectAnswers, 1)
        XCTAssertEqual(stats.accuracy, 67)
        XCTAssertEqual(stats.studyDays, 1)
        XCTAssertEqual(stats.activity.first?.reviewCount, 3)
        XCTAssertEqual(stats.activity.first?.newWordsCount, 1)
    }

    func testStudyActivityTracksStreakAcrossConsecutiveDays() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "Chinese")
        let first = try repository.createWord(languageID: language.id, text: "你好", translation: "привет")
        let second = try repository.createWord(languageID: language.id, text: "谢谢", translation: "спасибо")
        let dayOne = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 12)))
        let dayTwo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: dayOne))
        let dayThree = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: dayTwo))
        try repository.recordLearningAnswer(wordID: first.id, knewAnswer: true, reviewedAt: dayOne)
        try repository.recordLearningAnswer(wordID: second.id, knewAnswer: true, reviewedAt: dayTwo)
        try repository.recordLearningAnswer(wordID: first.id, knewAnswer: false, reviewedAt: dayThree)
        let stats = try repository.fetchLearningStatistics(for: dayThree, now: dayThree)
        XCTAssertEqual(stats.studyDays, 3)
        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.activity.count, 3)
        XCTAssertEqual(stats.activity.reduce(0) { $0 + $1.newWordsCount }, 2)
    }



    func testLearningProgressStatusMovesFromNewToLearningToMastered() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let initial = LearningProgress(wordID: "status-word")
        XCTAssertEqual(initial.status, .new)
        let first = SpacedRepetitionScheduler.applying(knewAnswer: true, to: initial, reviewedAt: start)
        XCTAssertEqual(first.status, .learning)
        let second = SpacedRepetitionScheduler.applying(knewAnswer: true, to: first, reviewedAt: start)
        XCTAssertEqual(second.status, .learning)
        let third = SpacedRepetitionScheduler.applying(knewAnswer: true, to: second, reviewedAt: start)
        XCTAssertEqual(third.status, .mastered)
        let forgotten = SpacedRepetitionScheduler.applying(knewAnswer: false, to: third, reviewedAt: start)
        XCTAssertEqual(forgotten.status, .learning)
    }



    func testAchievementsUnlockAtTheirDefinedMilestones() {
        let empty = LearningStatistics.empty
        XCTAssertFalse(StudyAchievement.all(for: empty).contains(where: \.isUnlocked))

        var progress = empty
        progress.totalWords = 50
        progress.masteredWords = 1
        progress.totalReviews = 100
        progress.currentStreak = 7

        let achievements = StudyAchievement.all(for: progress)
        XCTAssertTrue(achievements.first(where: { $0.id == "first_word" })?.isUnlocked == true)
        XCTAssertTrue(achievements.first(where: { $0.id == "word_collector" })?.isUnlocked == true)
        XCTAssertTrue(achievements.first(where: { $0.id == "first_mastered" })?.isUnlocked == true)
        XCTAssertTrue(achievements.first(where: { $0.id == "seven_day_streak" })?.isUnlocked == true)
        XCTAssertTrue(achievements.first(where: { $0.id == "hundred_reviews" })?.isUnlocked == true)
        XCTAssertFalse(achievements.first(where: { $0.id == "hundred_words" })?.isUnlocked ?? true)
    }



    func testBackupRoundTripPreservesRelationshipsProgressAndActivity() throws {
        let source = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try source.createLanguage(name: "Chinese", code: "zh")
        let parent = try source.createCategory(languageID: language.id, name: "Food")
        let child = try source.createCategory(languageID: language.id, name: "Fruit", parentID: parent.id)
        let firstSet = try source.createSet(languageID: language.id, name: "Market", categoryID: child.id, details: "Shopping words")
        let secondSet = try source.createSet(languageID: language.id, name: "Daily")
        let word = try source.createWord(languageID: language.id, text: "苹果", translation: "яблоко", transcription: "píngguǒ", notes: "Fruit", example: "我吃苹果", inSet: firstSet.id)
        try source.addWord(word.id, toSet: secondSet.id)
        let reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        try source.recordLearningAnswer(wordID: word.id, knewAnswer: true, reviewedAt: reviewedAt)

        let backup = try source.exportBackup()
        let encoded = try backup.encoded()
        let decoded = try LibraryBackup.decode(encoded)
        let destination = LibraryRepository(database: try DatabaseManager.inMemory())
        try destination.restoreBackup(decoded)

        XCTAssertEqual(try destination.fetchLanguages(), [language])
        XCTAssertEqual(try destination.fetchCategories(languageID: language.id), [parent, child])
        XCTAssertEqual(Set(try destination.fetchSets(containing: word.id).map(\\.id)), Set([firstSet.id, secondSet.id]))
        XCTAssertEqual(try destination.fetchProgress(for: word.id), try source.fetchProgress(for: word.id))
        XCTAssertEqual(try destination.fetchLearningStatistics(for: reviewedAt, now: reviewedAt).totalReviews, 1)
        XCTAssertEqual(try destination.fetchWords(inSet: firstSet.id).first?.example, "我吃苹果")
    }

    func testBackupRejectsInvalidRelationshipsWithoutChangingExistingLibrary() throws {
        let repository = LibraryRepository(database: try DatabaseManager.inMemory())
        let language = try repository.createLanguage(name: "English")
        let set = try repository.createSet(languageID: language.id, name: "Existing")
        let invalid = LibraryBackup(
            languages: [language],
            categories: [],
            sets: [VocabularySet(languageID: "missing", name: "Broken")],
            words: [],
            memberships: [],
            learningProgress: [],
            studyActivity: []
        )
        XCTAssertThrowsError(try repository.restoreBackup(invalid))
        XCTAssertEqual(try repository.fetchSets(languageID: language.id).map(\\.id), [set.id])
    }

}
