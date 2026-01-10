import Foundation

enum BibleData {
    static let books: [BibleBook] = [
        // Old Testament
        BibleBook(id: "genesis", nameEn: "Genesis", nameKr: "창세기", apiName: "genesis", chapterCount: 50, order: 1),
        BibleBook(id: "exodus", nameEn: "Exodus", nameKr: "출애굽기", apiName: "exodus", chapterCount: 40, order: 2),
        BibleBook(id: "leviticus", nameEn: "Leviticus", nameKr: "레위기", apiName: "leviticus", chapterCount: 27, order: 3),
        BibleBook(id: "numbers", nameEn: "Numbers", nameKr: "민수기", apiName: "numbers", chapterCount: 36, order: 4),
        BibleBook(id: "deuteronomy", nameEn: "Deuteronomy", nameKr: "신명기", apiName: "deuteronomy", chapterCount: 34, order: 5),
        BibleBook(id: "joshua", nameEn: "Joshua", nameKr: "여호수아", apiName: "joshua", chapterCount: 24, order: 6),
        BibleBook(id: "judges", nameEn: "Judges", nameKr: "사사기", apiName: "judges", chapterCount: 21, order: 7),
        BibleBook(id: "ruth", nameEn: "Ruth", nameKr: "룻기", apiName: "ruth", chapterCount: 4, order: 8),
        BibleBook(id: "1samuel", nameEn: "1 Samuel", nameKr: "사무엘상", apiName: "1samuel", chapterCount: 31, order: 9),
        BibleBook(id: "2samuel", nameEn: "2 Samuel", nameKr: "사무엘하", apiName: "2samuel", chapterCount: 24, order: 10),
        BibleBook(id: "1kings", nameEn: "1 Kings", nameKr: "열왕기상", apiName: "1kings", chapterCount: 22, order: 11),
        BibleBook(id: "2kings", nameEn: "2 Kings", nameKr: "열왕기하", apiName: "2kings", chapterCount: 25, order: 12),
        BibleBook(id: "1chronicles", nameEn: "1 Chronicles", nameKr: "역대상", apiName: "1chronicles", chapterCount: 29, order: 13),
        BibleBook(id: "2chronicles", nameEn: "2 Chronicles", nameKr: "역대하", apiName: "2chronicles", chapterCount: 36, order: 14),
        BibleBook(id: "ezra", nameEn: "Ezra", nameKr: "에스라", apiName: "ezra", chapterCount: 10, order: 15),
        BibleBook(id: "nehemiah", nameEn: "Nehemiah", nameKr: "느헤미야", apiName: "nehemiah", chapterCount: 13, order: 16),
        BibleBook(id: "esther", nameEn: "Esther", nameKr: "에스더", apiName: "esther", chapterCount: 10, order: 17),
        BibleBook(id: "job", nameEn: "Job", nameKr: "욥기", apiName: "job", chapterCount: 42, order: 18),
        BibleBook(id: "psalms", nameEn: "Psalms", nameKr: "시편", apiName: "psalms", chapterCount: 150, order: 19),
        BibleBook(id: "proverbs", nameEn: "Proverbs", nameKr: "잠언", apiName: "proverbs", chapterCount: 31, order: 20),
        BibleBook(id: "ecclesiastes", nameEn: "Ecclesiastes", nameKr: "전도서", apiName: "ecclesiastes", chapterCount: 12, order: 21),
        BibleBook(id: "songofsolomon", nameEn: "Song of Solomon", nameKr: "아가", apiName: "songofsolomon", chapterCount: 8, order: 22),
        BibleBook(id: "isaiah", nameEn: "Isaiah", nameKr: "이사야", apiName: "isaiah", chapterCount: 66, order: 23),
        BibleBook(id: "jeremiah", nameEn: "Jeremiah", nameKr: "예레미야", apiName: "jeremiah", chapterCount: 52, order: 24),
        BibleBook(id: "lamentations", nameEn: "Lamentations", nameKr: "예레미야애가", apiName: "lamentations", chapterCount: 5, order: 25),
        BibleBook(id: "ezekiel", nameEn: "Ezekiel", nameKr: "에스겔", apiName: "ezekiel", chapterCount: 48, order: 26),
        BibleBook(id: "daniel", nameEn: "Daniel", nameKr: "다니엘", apiName: "daniel", chapterCount: 12, order: 27),
        BibleBook(id: "hosea", nameEn: "Hosea", nameKr: "호세아", apiName: "hosea", chapterCount: 14, order: 28),
        BibleBook(id: "joel", nameEn: "Joel", nameKr: "요엘", apiName: "joel", chapterCount: 3, order: 29),
        BibleBook(id: "amos", nameEn: "Amos", nameKr: "아모스", apiName: "amos", chapterCount: 9, order: 30),
        BibleBook(id: "obadiah", nameEn: "Obadiah", nameKr: "오바댜", apiName: "obadiah", chapterCount: 1, order: 31),
        BibleBook(id: "jonah", nameEn: "Jonah", nameKr: "요나", apiName: "jonah", chapterCount: 4, order: 32),
        BibleBook(id: "micah", nameEn: "Micah", nameKr: "미가", apiName: "micah", chapterCount: 7, order: 33),
        BibleBook(id: "nahum", nameEn: "Nahum", nameKr: "나훔", apiName: "nahum", chapterCount: 3, order: 34),
        BibleBook(id: "habakkuk", nameEn: "Habakkuk", nameKr: "하박국", apiName: "habakkuk", chapterCount: 3, order: 35),
        BibleBook(id: "zephaniah", nameEn: "Zephaniah", nameKr: "스바냐", apiName: "zephaniah", chapterCount: 3, order: 36),
        BibleBook(id: "haggai", nameEn: "Haggai", nameKr: "학개", apiName: "haggai", chapterCount: 2, order: 37),
        BibleBook(id: "zechariah", nameEn: "Zechariah", nameKr: "스가랴", apiName: "zechariah", chapterCount: 14, order: 38),
        BibleBook(id: "malachi", nameEn: "Malachi", nameKr: "말라기", apiName: "malachi", chapterCount: 4, order: 39),
        
        // New Testament
        BibleBook(id: "matthew", nameEn: "Matthew", nameKr: "마태복음", apiName: "matthew", chapterCount: 28, order: 40),
        BibleBook(id: "mark", nameEn: "Mark", nameKr: "마가복음", apiName: "mark", chapterCount: 16, order: 41),
        BibleBook(id: "luke", nameEn: "Luke", nameKr: "누가복음", apiName: "luke", chapterCount: 24, order: 42),
        BibleBook(id: "john", nameEn: "John", nameKr: "요한복음", apiName: "john", chapterCount: 21, order: 43),
        BibleBook(id: "acts", nameEn: "Acts", nameKr: "사도행전", apiName: "acts", chapterCount: 28, order: 44),
        BibleBook(id: "romans", nameEn: "Romans", nameKr: "로마서", apiName: "romans", chapterCount: 16, order: 45),
        BibleBook(id: "1corinthians", nameEn: "1 Corinthians", nameKr: "고린도전서", apiName: "1corinthians", chapterCount: 16, order: 46),
        BibleBook(id: "2corinthians", nameEn: "2 Corinthians", nameKr: "고린도후서", apiName: "2corinthians", chapterCount: 13, order: 47),
        BibleBook(id: "galatians", nameEn: "Galatians", nameKr: "갈라디아서", apiName: "galatians", chapterCount: 6, order: 48),
        BibleBook(id: "ephesians", nameEn: "Ephesians", nameKr: "에베소서", apiName: "ephesians", chapterCount: 6, order: 49),
        BibleBook(id: "philippians", nameEn: "Philippians", nameKr: "빌립보서", apiName: "philippians", chapterCount: 4, order: 50),
        BibleBook(id: "colossians", nameEn: "Colossians", nameKr: "골로새서", apiName: "colossians", chapterCount: 4, order: 51),
        BibleBook(id: "1thessalonians", nameEn: "1 Thessalonians", nameKr: "데살로니가전서", apiName: "1thessalonians", chapterCount: 5, order: 52),
        BibleBook(id: "2thessalonians", nameEn: "2 Thessalonians", nameKr: "데살로니가후서", apiName: "2thessalonians", chapterCount: 3, order: 53),
        BibleBook(id: "1timothy", nameEn: "1 Timothy", nameKr: "디모데전서", apiName: "1timothy", chapterCount: 6, order: 54),
        BibleBook(id: "2timothy", nameEn: "2 Timothy", nameKr: "디모데후서", apiName: "2timothy", chapterCount: 4, order: 55),
        BibleBook(id: "titus", nameEn: "Titus", nameKr: "디도서", apiName: "titus", chapterCount: 3, order: 56),
        BibleBook(id: "philemon", nameEn: "Philemon", nameKr: "빌레몬서", apiName: "philemon", chapterCount: 1, order: 57),
        BibleBook(id: "hebrews", nameEn: "Hebrews", nameKr: "히브리서", apiName: "hebrews", chapterCount: 13, order: 58),
        BibleBook(id: "james", nameEn: "James", nameKr: "야고보서", apiName: "james", chapterCount: 5, order: 59),
        BibleBook(id: "1peter", nameEn: "1 Peter", nameKr: "베드로전서", apiName: "1peter", chapterCount: 5, order: 60),
        BibleBook(id: "2peter", nameEn: "2 Peter", nameKr: "베드로후서", apiName: "2peter", chapterCount: 3, order: 61),
        BibleBook(id: "1john", nameEn: "1 John", nameKr: "요한일서", apiName: "1john", chapterCount: 5, order: 62),
        BibleBook(id: "2john", nameEn: "2 John", nameKr: "요한이서", apiName: "2john", chapterCount: 1, order: 63),
        BibleBook(id: "3john", nameEn: "3 John", nameKr: "요한삼서", apiName: "3john", chapterCount: 1, order: 64),
        BibleBook(id: "jude", nameEn: "Jude", nameKr: "유다서", apiName: "jude", chapterCount: 1, order: 65),
        BibleBook(id: "revelation", nameEn: "Revelation", nameKr: "요한계시록", apiName: "revelation", chapterCount: 22, order: 66)
    ]
    
    static func book(by id: String) -> BibleBook? {
        books.first { $0.id == id }
    }
    
    static func book(at order: Int) -> BibleBook? {
        books.first { $0.order == order }
    }
    
    static func nextBook(after book: BibleBook) -> BibleBook? {
        guard book.order < 66 else { return nil }
        return self.book(at: book.order + 1)
    }
    
    static func previousBook(before book: BibleBook) -> BibleBook? {
        guard book.order > 1 else { return nil }
        return self.book(at: book.order - 1)
    }
    
    static func sortedBooks(by sortOrder: BookSortOrder, language: LanguageMode) -> [BibleBook] {
        switch sortOrder {
        case .canonical:
            return books.sorted { $0.order < $1.order }
        case .alphabetical:
            return books.sorted { book1, book2 in
                let name1 = book1.name(for: language)
                let name2 = book2.name(for: language)
                
                if language == .kr {
                    // Korean Ganada order
                    return name1.compare(name2, locale: Locale(identifier: "ko_KR")) == .orderedAscending
                } else {
                    return name1.localizedStandardCompare(name2) == .orderedAscending
                }
            }
        }
    }
    
    // Single-chapter book IDs for easy reference
    static let singleChapterBookIds: Set<String> = ["obadiah", "philemon", "2john", "3john", "jude"]
}
