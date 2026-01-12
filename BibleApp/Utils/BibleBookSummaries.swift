//
//  BibleBookSummaries.swift
//  BibleApp
//
//  Bible book summaries, messages, and timeline data
//

import Foundation

struct BibleBookSummary: Identifiable, Codable {
    let id: String            // Matches BibleBook.id (e.g., "genesis", "exodus")
    let bookNumber: Int       // API book number 1-66 (matches BibleBook.order)
    let bookKo: String
    let bookEn: String
    let category: String
    let summaryKo: String
    let summaryEn: String
    let messageKo: String
    let messageEn: String
    let yearWritten: Int      // Approximate year written (negative = BC, positive = AD)
    let yearEvents: Int?      // Approximate year of events described (if different from written)
    
    var displayYear: String {
        let year = yearEvents ?? yearWritten
        if year < 0 {
            return "\(abs(year)) BC"
        } else {
            return "\(year) AD"
        }
    }
}

struct BibleBookSummaries {
    static let all: [BibleBookSummary] = [
        // ============================================================
        // OLD TESTAMENT - PENTATEUCH (모세오경)
        // ============================================================
        BibleBookSummary(
            id: "genesis",
            bookNumber: 1,
            bookKo: "창세기",
            bookEn: "Genesis",
            category: "Pentateuch",
            summaryKo: "세상의 시작과 인류의 타락, 그리고 하나님이 선택하신 족장들의 이야기를 다룹니다.",
            summaryEn: "Covers the beginning of the world, the fall of humanity, and the stories of the chosen patriarchs.",
            messageKo: "모든 만물은 하나님의 목적 아래 시작되었으며, 인간의 실수에도 하나님의 구원 계획은 멈추지 않습니다.",
            messageEn: "Everything began with God's purpose, and His plan for salvation never stops despite human failure.",
            yearWritten: -1450,
            yearEvents: -2000
        ),
        BibleBookSummary(
            id: "exodus",
            bookNumber: 2,
            bookKo: "출애굽기",
            bookEn: "Exodus",
            category: "Pentateuch",
            summaryKo: "이집트에서 노예 생활을 하던 이스라엘 백성이 모세의 인도로 탈출하여 시내산에서 언약을 맺는 과정입니다.",
            summaryEn: "The story of the Israelites' escape from slavery in Egypt under Moses and their covenant at Mount Sinai.",
            messageKo: "하나님은 고난받는 자의 부르짖음을 들으시며, 약속을 반드시 지키시는 구원자이십니다.",
            messageEn: "God hears the cries of the suffering and is a deliverer who always keeps His promises.",
            yearWritten: -1450,
            yearEvents: -1446
        ),
        BibleBookSummary(
            id: "leviticus",
            bookNumber: 3,
            bookKo: "레위기",
            bookEn: "Leviticus",
            category: "Pentateuch",
            summaryKo: "제사 제도와 정결 규례를 통해 거룩한 하나님께 어떻게 나아가야 하는지를 가르칩니다.",
            summaryEn: "Teaches how to approach the holy God through the sacrificial system and purity laws.",
            messageKo: "거룩하신 하나님은 우리가 그분께 가까이 나아갈 수 있는 길을 열어주셨습니다.",
            messageEn: "The holy God has opened a way for us to draw near to Him.",
            yearWritten: -1445,
            yearEvents: -1445
        ),
        BibleBookSummary(
            id: "numbers",
            bookNumber: 4,
            bookKo: "민수기",
            bookEn: "Numbers",
            category: "Pentateuch",
            summaryKo: "이스라엘 백성이 광야에서 40년간 방황하며 겪은 시험과 불평, 그리고 하나님의 인내를 기록합니다.",
            summaryEn: "Records the 40-year wilderness wandering, the trials, complaints, and God's patience with Israel.",
            messageKo: "불신앙은 약속의 성취를 지연시키지만, 하나님의 신실하심은 변함이 없습니다.",
            messageEn: "Unbelief delays the fulfillment of promises, but God's faithfulness remains unchanged.",
            yearWritten: -1406,
            yearEvents: -1445
        ),
        BibleBookSummary(
            id: "deuteronomy",
            bookNumber: 5,
            bookKo: "신명기",
            bookEn: "Deuteronomy",
            category: "Pentateuch",
            summaryKo: "모세가 새 세대에게 율법을 다시 선포하고, 가나안 입성을 앞두고 언약 갱신을 촉구합니다.",
            summaryEn: "Moses restates the law to the new generation and calls for covenant renewal before entering Canaan.",
            messageKo: "하나님을 사랑하고 그분의 말씀에 순종하는 것이 참된 복의 비결입니다.",
            messageEn: "Loving God and obeying His word is the secret to true blessing.",
            yearWritten: -1406,
            yearEvents: -1406
        ),
        
        // ============================================================
        // OLD TESTAMENT - HISTORICAL BOOKS (역사서)
        // ============================================================
        BibleBookSummary(
            id: "joshua",
            bookNumber: 6,
            bookKo: "여호수아",
            bookEn: "Joshua",
            category: "History",
            summaryKo: "여호수아의 인도 아래 이스라엘이 가나안 땅을 정복하고 지파별로 분배받는 이야기입니다.",
            summaryEn: "The story of Israel's conquest of Canaan under Joshua's leadership and the land distribution among tribes.",
            messageKo: "하나님의 약속은 반드시 성취되며, 믿음으로 담대히 나아가는 자에게 승리가 있습니다.",
            messageEn: "God's promises are always fulfilled, and victory belongs to those who step forward in faith.",
            yearWritten: -1390,
            yearEvents: -1406
        ),
        BibleBookSummary(
            id: "judges",
            bookNumber: 7,
            bookKo: "사사기",
            bookEn: "Judges",
            category: "History",
            summaryKo: "이스라엘이 하나님을 떠나 우상을 섬기고, 사사들을 통해 구원받는 순환이 반복됩니다.",
            summaryEn: "Israel repeatedly turns to idolatry and is delivered through judges in a recurring cycle.",
            messageKo: "각자 자기 소견대로 행할 때 혼란이 오지만, 하나님은 여전히 구원의 손길을 내미십니다.",
            messageEn: "Chaos comes when everyone does what is right in their own eyes, yet God still extends His saving hand.",
            yearWritten: -1050,
            yearEvents: -1380
        ),
        BibleBookSummary(
            id: "ruth",
            bookNumber: 8,
            bookKo: "룻기",
            bookEn: "Ruth",
            category: "History",
            summaryKo: "모압 여인 룻이 시어머니 나오미를 따라 이스라엘로 와서 보아스를 만나 다윗의 조상이 됩니다.",
            summaryEn: "Ruth, a Moabite woman, follows her mother-in-law Naomi to Israel, meets Boaz, and becomes an ancestor of David.",
            messageKo: "하나님의 은혜는 민족의 경계를 넘어 신실한 자에게 임하며, 작은 순종이 큰 역사를 만듭니다.",
            messageEn: "God's grace transcends ethnic boundaries and comes to the faithful; small acts of obedience create great history.",
            yearWritten: -1010,
            yearEvents: -1100
        ),
        BibleBookSummary(
            id: "1samuel",
            bookNumber: 9,
            bookKo: "사무엘상",
            bookEn: "1 Samuel",
            category: "History",
            summaryKo: "사무엘의 탄생과 사역, 사울의 등극과 몰락, 그리고 다윗의 부상을 기록합니다.",
            summaryEn: "Records the birth and ministry of Samuel, the rise and fall of Saul, and the emergence of David.",
            messageKo: "하나님은 외모가 아닌 중심을 보시며, 겸손히 순종하는 자를 높이십니다.",
            messageEn: "God looks at the heart, not outward appearance, and exalts those who humbly obey.",
            yearWritten: -930,
            yearEvents: -1050
        ),
        BibleBookSummary(
            id: "2samuel",
            bookNumber: 10,
            bookKo: "사무엘하",
            bookEn: "2 Samuel",
            category: "History",
            summaryKo: "다윗 왕의 통치, 그의 죄와 회개, 그리고 가정과 나라에 닥친 시련을 다룹니다.",
            summaryEn: "Covers David's reign, his sin and repentance, and the trials that came upon his family and kingdom.",
            messageKo: "죄에는 결과가 따르지만, 진심 어린 회개 앞에 하나님의 용서와 회복이 있습니다.",
            messageEn: "Sin has consequences, but before sincere repentance, there is God's forgiveness and restoration.",
            yearWritten: -930,
            yearEvents: -1010
        ),
        BibleBookSummary(
            id: "1kings",
            bookNumber: 11,
            bookKo: "열왕기상",
            bookEn: "1 Kings",
            category: "History",
            summaryKo: "솔로몬의 영광과 타락, 왕국 분열, 엘리야의 사역을 기록합니다.",
            summaryEn: "Records Solomon's glory and decline, the division of the kingdom, and Elijah's ministry.",
            messageKo: "지혜와 축복은 하나님께 대한 충성 없이는 지속될 수 없습니다.",
            messageEn: "Wisdom and blessing cannot be sustained without faithfulness to God.",
            yearWritten: -560,
            yearEvents: -970
        ),
        BibleBookSummary(
            id: "2kings",
            bookNumber: 12,
            bookKo: "열왕기하",
            bookEn: "2 Kings",
            category: "History",
            summaryKo: "분열 왕국의 역사와 선지자들의 활동, 그리고 북이스라엘과 남유다의 멸망을 기록합니다.",
            summaryEn: "Records the history of the divided kingdoms, prophetic activity, and the fall of both Israel and Judah.",
            messageKo: "지속적인 불순종은 심판을 초래하지만, 하나님은 회개하는 자에게 소망을 주십니다.",
            messageEn: "Persistent disobedience brings judgment, but God gives hope to those who repent.",
            yearWritten: -560,
            yearEvents: -850
        ),
        BibleBookSummary(
            id: "1chronicles",
            bookNumber: 13,
            bookKo: "역대상",
            bookEn: "1 Chronicles",
            category: "History",
            summaryKo: "아담부터 다윗까지의 족보와 다윗 왕의 통치를 제사장적 관점에서 재조명합니다.",
            summaryEn: "Presents genealogies from Adam to David and reexamines David's reign from a priestly perspective.",
            messageKo: "하나님의 백성은 예배 공동체이며, 다윗의 언약은 영원한 왕국을 가리킵니다.",
            messageEn: "God's people are a worshiping community, and David's covenant points to an eternal kingdom.",
            yearWritten: -450,
            yearEvents: -1000
        ),
        BibleBookSummary(
            id: "2chronicles",
            bookNumber: 14,
            bookKo: "역대하",
            bookEn: "2 Chronicles",
            category: "History",
            summaryKo: "솔로몬의 성전 건축부터 바빌론 포로기까지 유다 왕국의 역사를 다룹니다.",
            summaryEn: "Covers Judah's history from Solomon's temple construction to the Babylonian exile.",
            messageKo: "성전에서의 참된 예배와 하나님께 대한 신실함이 나라의 흥망을 결정합니다.",
            messageEn: "True worship in the temple and faithfulness to God determine the rise and fall of nations.",
            yearWritten: -450,
            yearEvents: -970
        ),
        BibleBookSummary(
            id: "ezra",
            bookNumber: 15,
            bookKo: "에스라",
            bookEn: "Ezra",
            category: "History",
            summaryKo: "바빌론 포로에서 돌아온 백성이 성전을 재건하고 율법을 회복하는 과정입니다.",
            summaryEn: "The story of the exiles' return from Babylon, rebuilding the temple, and restoring the law.",
            messageKo: "하나님은 회복의 하나님이시며, 말씀으로 돌아갈 때 새로운 시작이 가능합니다.",
            messageEn: "God is a God of restoration, and a new beginning is possible when we return to His Word.",
            yearWritten: -450,
            yearEvents: -538
        ),
        BibleBookSummary(
            id: "nehemiah",
            bookNumber: 16,
            bookKo: "느헤미야",
            bookEn: "Nehemiah",
            category: "History",
            summaryKo: "느헤미야의 지도 아래 예루살렘 성벽을 재건하고 공동체를 개혁하는 이야기입니다.",
            summaryEn: "The story of rebuilding Jerusalem's walls and reforming the community under Nehemiah's leadership.",
            messageKo: "기도와 실천이 결합될 때, 불가능해 보이는 일도 하나님 안에서 이루어집니다.",
            messageEn: "When prayer and action combine, the impossible becomes possible in God.",
            yearWritten: -430,
            yearEvents: -445
        ),
        BibleBookSummary(
            id: "esther",
            bookNumber: 17,
            bookKo: "에스더",
            bookEn: "Esther",
            category: "History",
            summaryKo: "페르시아 제국에서 에스더 왕비가 유대 민족의 멸절 위기를 막아낸 이야기입니다.",
            summaryEn: "Queen Esther saves the Jewish people from annihilation in the Persian Empire.",
            messageKo: "하나님의 이름이 직접 언급되지 않아도, 그분의 섭리는 역사 속에서 일하고 계십니다.",
            messageEn: "Even when God's name is not mentioned, His providence is at work in history.",
            yearWritten: -465,
            yearEvents: -473
        ),
        
        // ============================================================
        // OLD TESTAMENT - WISDOM/POETRY (지혜서/시가서)
        // ============================================================
        BibleBookSummary(
            id: "job",
            bookNumber: 18,
            bookKo: "욥기",
            bookEn: "Job",
            category: "Wisdom",
            summaryKo: "의로운 욥이 고난을 당하고, 하나님과의 대화를 통해 신뢰를 회복하는 이야기입니다.",
            summaryEn: "Righteous Job suffers and regains trust through dialogue with God.",
            messageKo: "고난의 이유를 다 알 수 없지만, 하나님은 선하시며 신뢰받기에 합당하십니다.",
            messageEn: "We cannot understand all the reasons for suffering, but God is good and worthy of trust.",
            yearWritten: -2000,
            yearEvents: -2000
        ),
        BibleBookSummary(
            id: "psalms",
            bookNumber: 19,
            bookKo: "시편",
            bookEn: "Psalms",
            category: "Wisdom",
            summaryKo: "다양한 상황 속에서 하나님을 찬양하고, 탄식하며, 신뢰하는 150개의 기도와 노래 모음입니다.",
            summaryEn: "A collection of 150 prayers and songs praising, lamenting, and trusting God in various situations.",
            messageKo: "우리의 모든 감정을 하나님께 정직하게 쏟아낼 수 있으며, 그분은 우리의 참된 피난처이십니다.",
            messageEn: "We can honestly pour out all our emotions to God, who is our true refuge.",
            yearWritten: -1000,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "proverbs",
            bookNumber: 20,
            bookKo: "잠언",
            bookEn: "Proverbs",
            category: "Wisdom",
            summaryKo: "일상생활에서의 지혜로운 삶을 위한 교훈과 금언을 담고 있습니다.",
            summaryEn: "Contains teachings and maxims for wise living in everyday life.",
            messageKo: "여호와를 경외하는 것이 지혜의 근본이며, 지혜는 삶의 모든 영역에서 필요합니다.",
            messageEn: "The fear of the Lord is the beginning of wisdom, and wisdom is needed in every area of life.",
            yearWritten: -950,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "ecclesiastes",
            bookNumber: 21,
            bookKo: "전도서",
            bookEn: "Ecclesiastes",
            category: "Wisdom",
            summaryKo: "인생의 허무함을 탐구하고, 하나님 없이는 참된 의미를 찾을 수 없음을 깨닫습니다.",
            summaryEn: "Explores the meaninglessness of life and concludes that true meaning cannot be found apart from God.",
            messageKo: "해 아래 모든 것은 헛되지만, 하나님을 경외하고 그 명령을 지키는 것이 사람의 본분입니다.",
            messageEn: "Everything under the sun is meaningless, but fearing God and keeping His commands is the whole duty of man.",
            yearWritten: -935,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "songofsolomon",
            bookNumber: 22,
            bookKo: "아가",
            bookEn: "Song of Solomon",
            category: "Wisdom",
            summaryKo: "신랑과 신부 사이의 사랑을 노래하며, 하나님과 백성의 관계를 상징합니다.",
            summaryEn: "A song of love between a bridegroom and bride, symbolizing the relationship between God and His people.",
            messageKo: "사랑은 죽음같이 강하며, 하나님은 그의 백성을 열정적으로 사랑하십니다.",
            messageEn: "Love is as strong as death, and God loves His people with passion.",
            yearWritten: -950,
            yearEvents: nil
        ),
        
        // ============================================================
        // OLD TESTAMENT - MAJOR PROPHETS (대선지서)
        // ============================================================
        BibleBookSummary(
            id: "isaiah",
            bookNumber: 23,
            bookKo: "이사야",
            bookEn: "Isaiah",
            category: "Major Prophets",
            summaryKo: "유다의 죄를 책망하고, 메시아의 오심과 회복의 소망을 예언합니다.",
            summaryEn: "Rebukes Judah's sin and prophesies the coming of the Messiah and the hope of restoration.",
            messageKo: "심판 중에도 구원의 소망이 있으며, 고난받는 종이 우리를 대신하여 상함을 받으셨습니다.",
            messageEn: "Even in judgment there is hope for salvation; the Suffering Servant was wounded for us.",
            yearWritten: -700,
            yearEvents: -740
        ),
        BibleBookSummary(
            id: "jeremiah",
            bookNumber: 24,
            bookKo: "예레미야",
            bookEn: "Jeremiah",
            category: "Major Prophets",
            summaryKo: "눈물의 선지자 예레미야가 유다의 멸망을 경고하고 새 언약을 예언합니다.",
            summaryEn: "The weeping prophet Jeremiah warns of Judah's destruction and prophesies the new covenant.",
            messageKo: "하나님은 마음에 새기는 새 언약을 통해 참된 회복을 이루실 것입니다.",
            messageEn: "God will bring true restoration through a new covenant written on the heart.",
            yearWritten: -586,
            yearEvents: -627
        ),
        BibleBookSummary(
            id: "lamentations",
            bookNumber: 25,
            bookKo: "예레미야애가",
            bookEn: "Lamentations",
            category: "Major Prophets",
            summaryKo: "예루살렘 멸망에 대한 슬픔과 애통을 담은 애가입니다.",
            summaryEn: "Laments expressing sorrow and grief over the destruction of Jerusalem.",
            messageKo: "가장 깊은 슬픔 속에서도 하나님의 인자하심은 아침마다 새롭습니다.",
            messageEn: "Even in the deepest sorrow, God's mercies are new every morning.",
            yearWritten: -586,
            yearEvents: -586
        ),
        BibleBookSummary(
            id: "ezekiel",
            bookNumber: 26,
            bookKo: "에스겔",
            bookEn: "Ezekiel",
            category: "Major Prophets",
            summaryKo: "바빌론 포로 중에 있는 선지자가 환상을 통해 심판과 회복을 선포합니다.",
            summaryEn: "A prophet in Babylonian exile proclaims judgment and restoration through visions.",
            messageKo: "하나님의 영광은 성전을 떠나시지만, 마른 뼈도 살리시는 분이 새 마음을 주실 것입니다.",
            messageEn: "God's glory departs from the temple, but He who gives life to dry bones will give a new heart.",
            yearWritten: -570,
            yearEvents: -593
        ),
        BibleBookSummary(
            id: "daniel",
            bookNumber: 27,
            bookKo: "다니엘",
            bookEn: "Daniel",
            category: "Major Prophets",
            summaryKo: "바빌론과 페르시아에서의 다니엘의 신앙과 미래 왕국에 대한 예언을 담고 있습니다.",
            summaryEn: "Contains Daniel's faith in Babylon and Persia and prophecies about future kingdoms.",
            messageKo: "세상 왕국은 흥하고 망하지만, 하나님의 나라는 영원히 서 있을 것입니다.",
            messageEn: "Earthly kingdoms rise and fall, but God's kingdom will stand forever.",
            yearWritten: -536,
            yearEvents: -605
        ),
        
        // ============================================================
        // OLD TESTAMENT - MINOR PROPHETS (소선지서)
        // ============================================================
        BibleBookSummary(
            id: "hosea",
            bookNumber: 28,
            bookKo: "호세아",
            bookEn: "Hosea",
            category: "Minor Prophets",
            summaryKo: "불신실한 아내를 향한 호세아의 사랑을 통해 이스라엘을 향한 하나님의 사랑을 보여줍니다.",
            summaryEn: "Hosea's love for his unfaithful wife illustrates God's love for Israel.",
            messageKo: "아무리 불신실해도 하나님은 우리를 포기하지 않으시고 다시 부르십니다.",
            messageEn: "No matter how unfaithful we are, God never gives up on us and calls us back.",
            yearWritten: -725,
            yearEvents: -755
        ),
        BibleBookSummary(
            id: "joel",
            bookNumber: 29,
            bookKo: "요엘",
            bookEn: "Joel",
            category: "Minor Prophets",
            summaryKo: "메뚜기 재앙을 계기로 회개를 촉구하고, 성령 부어주심의 날을 예언합니다.",
            summaryEn: "Calls for repentance in the wake of a locust plague and prophesies the outpouring of the Spirit.",
            messageKo: "하나님께 돌아오면 회복이 있으며, 주의 날에 성령을 모든 육체에 부어주실 것입니다.",
            messageEn: "Restoration comes when we return to God, and He will pour out His Spirit on all flesh in the last days.",
            yearWritten: -835,
            yearEvents: -835
        ),
        BibleBookSummary(
            id: "amos",
            bookNumber: 30,
            bookKo: "아모스",
            bookEn: "Amos",
            category: "Minor Prophets",
            summaryKo: "목자 출신 선지자가 사회적 불의와 형식적 종교를 책망합니다.",
            summaryEn: "A shepherd-turned-prophet denounces social injustice and empty religious rituals.",
            messageKo: "하나님은 공의를 물같이, 정의를 마르지 않는 강같이 흐르게 하길 원하십니다.",
            messageEn: "God desires justice to roll on like a river and righteousness like a never-failing stream.",
            yearWritten: -760,
            yearEvents: -760
        ),
        BibleBookSummary(
            id: "obadiah",
            bookNumber: 31,
            bookKo: "오바댜",
            bookEn: "Obadiah",
            category: "Minor Prophets",
            summaryKo: "형제 나라 에돔의 교만과 배신에 대한 심판을 선포합니다.",
            summaryEn: "Pronounces judgment on Edom for its pride and betrayal of its brother nation.",
            messageKo: "교만은 패망의 선봉이며, 형제를 대적하는 자는 심판을 피할 수 없습니다.",
            messageEn: "Pride goes before destruction, and those who oppose their brothers cannot escape judgment.",
            yearWritten: -586,
            yearEvents: -586
        ),
        BibleBookSummary(
            id: "jonah",
            bookNumber: 32,
            bookKo: "요나",
            bookEn: "Jonah",
            category: "Minor Prophets",
            summaryKo: "요나가 니느웨 전도를 피하다 물고기 뱃속에서 회개하고 사명을 완수합니다.",
            summaryEn: "Jonah flees from his mission to Nineveh, repents in a fish's belly, and completes his calling.",
            messageKo: "하나님의 긍휼은 우리의 편견을 초월하며, 원수까지도 품으시는 사랑입니다.",
            messageEn: "God's compassion transcends our prejudices and embraces even our enemies.",
            yearWritten: -760,
            yearEvents: -760
        ),
        BibleBookSummary(
            id: "micah",
            bookNumber: 33,
            bookKo: "미가",
            bookEn: "Micah",
            category: "Minor Prophets",
            summaryKo: "사회적 불의를 고발하고, 베들레헴에서 오실 통치자를 예언합니다.",
            summaryEn: "Condemns social injustice and prophesies a ruler who will come from Bethlehem.",
            messageKo: "하나님이 원하시는 것은 공의를 행하고 인자를 사랑하며 겸손히 동행하는 것입니다.",
            messageEn: "What God requires is to act justly, love mercy, and walk humbly with Him.",
            yearWritten: -700,
            yearEvents: -735
        ),
        BibleBookSummary(
            id: "nahum",
            bookNumber: 34,
            bookKo: "나훔",
            bookEn: "Nahum",
            category: "Minor Prophets",
            summaryKo: "앗수르의 수도 니느웨의 멸망을 예언하며 하나님의 공의를 선포합니다.",
            summaryEn: "Prophesies the destruction of Nineveh, Assyria's capital, and proclaims God's justice.",
            messageKo: "압제자도 결국 심판받으며, 하나님은 그 백성을 보호하시는 피난처이십니다.",
            messageEn: "Oppressors will ultimately face judgment, and God is a refuge for His people.",
            yearWritten: -650,
            yearEvents: -650
        ),
        BibleBookSummary(
            id: "habakkuk",
            bookNumber: 35,
            bookKo: "하박국",
            bookEn: "Habakkuk",
            category: "Minor Prophets",
            summaryKo: "악의 존재와 하나님의 침묵에 대해 질문하고, 믿음으로 사는 길을 발견합니다.",
            summaryEn: "Questions the existence of evil and God's silence, and discovers the way of living by faith.",
            messageKo: "이해할 수 없는 상황에서도 의인은 믿음으로 살 것입니다.",
            messageEn: "Even in incomprehensible situations, the righteous will live by faith.",
            yearWritten: -609,
            yearEvents: -609
        ),
        BibleBookSummary(
            id: "zephaniah",
            bookNumber: 36,
            bookKo: "스바냐",
            bookEn: "Zephaniah",
            category: "Minor Prophets",
            summaryKo: "주의 심판의 날을 경고하고, 겸손한 남은 자의 회복을 약속합니다.",
            summaryEn: "Warns of the Day of the Lord's judgment and promises restoration for the humble remnant.",
            messageKo: "주의 날이 가까우니 겸손히 주를 찾으라, 그가 기쁨으로 너를 노래하시리라.",
            messageEn: "The Day of the Lord is near; seek Him humbly, for He will rejoice over you with singing.",
            yearWritten: -630,
            yearEvents: -630
        ),
        BibleBookSummary(
            id: "haggai",
            bookNumber: 37,
            bookKo: "학개",
            bookEn: "Haggai",
            category: "Minor Prophets",
            summaryKo: "성전 재건이 중단된 백성에게 하나님의 집을 먼저 세우라고 촉구합니다.",
            summaryEn: "Urges the people who stopped rebuilding the temple to prioritize God's house.",
            messageKo: "하나님의 일을 우선순위에 둘 때, 나머지 모든 것이 제자리를 찾습니다.",
            messageEn: "When we put God's work first, everything else falls into place.",
            yearWritten: -520,
            yearEvents: -520
        ),
        BibleBookSummary(
            id: "zechariah",
            bookNumber: 38,
            bookKo: "스가랴",
            bookEn: "Zechariah",
            category: "Minor Prophets",
            summaryKo: "환상과 예언을 통해 메시아의 오심과 최종적 승리를 선포합니다.",
            summaryEn: "Through visions and prophecies, proclaims the coming of the Messiah and ultimate victory.",
            messageKo: "능력으로 되지 아니하고 힘으로 되지 아니하고 오직 주의 영으로 됩니다.",
            messageEn: "Not by might nor by power, but by my Spirit, says the Lord.",
            yearWritten: -480,
            yearEvents: -520
        ),
        BibleBookSummary(
            id: "malachi",
            bookNumber: 39,
            bookKo: "말라기",
            bookEn: "Malachi",
            category: "Minor Prophets",
            summaryKo: "포로 귀환 후 타락한 제사장들과 백성의 불성실을 책망하고 메시아의 선구자를 예언합니다.",
            summaryEn: "Rebukes corrupt priests and unfaithful people after the exile, prophesying the Messiah's forerunner.",
            messageKo: "의로운 태양이 떠오르기 전 선구자가 올 것이며, 하나님은 변함없이 사랑하십니다.",
            messageEn: "A forerunner will come before the Sun of Righteousness rises, and God's love never changes.",
            yearWritten: -430,
            yearEvents: -430
        ),
        
        // ============================================================
        // NEW TESTAMENT - GOSPELS (복음서)
        // ============================================================
        BibleBookSummary(
            id: "matthew",
            bookNumber: 40,
            bookKo: "마태복음",
            bookEn: "Matthew",
            category: "Gospels",
            summaryKo: "약속된 메시아로서 오신 예수 그리스도의 생애와 가르침, 그리고 부활을 기록합니다.",
            summaryEn: "Records the life, teachings, and resurrection of Jesus Christ, who came as the promised Messiah.",
            messageKo: "예수님은 하늘과 땅의 모든 권세를 가지신 우리의 진정한 왕이십니다.",
            messageEn: "Jesus is our true King who holds all authority in heaven and on earth.",
            yearWritten: 55,
            yearEvents: 30
        ),
        BibleBookSummary(
            id: "mark",
            bookNumber: 41,
            bookKo: "마가복음",
            bookEn: "Mark",
            category: "Gospels",
            summaryKo: "행동하시는 종으로서의 예수님의 사역과 십자가의 길을 간결하게 기록합니다.",
            summaryEn: "Concisely records Jesus' ministry and path to the cross as the active servant.",
            messageKo: "인자가 온 것은 섬김을 받으려 함이 아니라 섬기려 하고 많은 사람의 대속물로 주려 함이라.",
            messageEn: "The Son of Man came not to be served but to serve, and to give His life as a ransom for many.",
            yearWritten: 55,
            yearEvents: 30
        ),
        BibleBookSummary(
            id: "luke",
            bookNumber: 42,
            bookKo: "누가복음",
            bookEn: "Luke",
            category: "Gospels",
            summaryKo: "소외된 자들을 찾아오신 인자이신 예수님의 사랑과 구원 사역을 상세히 기록합니다.",
            summaryEn: "Details Jesus' love and saving ministry as the Son of Man who came for the marginalized.",
            messageKo: "인자가 온 것은 잃어버린 자를 찾아 구원하려 함이라.",
            messageEn: "The Son of Man came to seek and save the lost.",
            yearWritten: 60,
            yearEvents: 30
        ),
        BibleBookSummary(
            id: "john",
            bookNumber: 43,
            bookKo: "요한복음",
            bookEn: "John",
            category: "Gospels",
            summaryKo: "하나님의 아들이신 예수님의 신성과 영원한 생명을 주시는 사역을 증거합니다.",
            summaryEn: "Testifies to the deity of Jesus as the Son of God and His ministry of giving eternal life.",
            messageKo: "예수님은 길이요 진리요 생명이시며, 그를 믿는 자는 영생을 얻습니다.",
            messageEn: "Jesus is the way, the truth, and the life; whoever believes in Him has eternal life.",
            yearWritten: 90,
            yearEvents: 30
        ),
        
        // ============================================================
        // NEW TESTAMENT - HISTORY (역사서)
        // ============================================================
        BibleBookSummary(
            id: "acts",
            bookNumber: 44,
            bookKo: "사도행전",
            bookEn: "Acts",
            category: "History",
            summaryKo: "성령의 능력으로 교회가 시작되고 복음이 예루살렘에서 로마까지 퍼져나가는 역사입니다.",
            summaryEn: "The history of the church beginning with the Holy Spirit's power and the gospel spreading from Jerusalem to Rome.",
            messageKo: "성령의 능력으로 땅끝까지 복음이 전파되며, 교회는 핍박 속에서도 성장합니다.",
            messageEn: "The gospel spreads to the ends of the earth by the power of the Holy Spirit, and the church grows even through persecution.",
            yearWritten: 63,
            yearEvents: 30
        ),
        
        // ============================================================
        // NEW TESTAMENT - PAULINE EPISTLES (바울서신)
        // ============================================================
        BibleBookSummary(
            id: "romans",
            bookNumber: 45,
            bookKo: "로마서",
            bookEn: "Romans",
            category: "Pauline Epistles",
            summaryKo: "복음의 핵심인 이신칭의(믿음으로 의롭게 됨)를 체계적으로 설명합니다.",
            summaryEn: "Systematically explains justification by faith, the core of the gospel.",
            messageKo: "의인은 없나니 하나도 없으나, 믿음으로 말미암아 은혜로 의롭다 하심을 받습니다.",
            messageEn: "There is no one righteous, not even one, but we are justified by grace through faith.",
            yearWritten: 57,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "1corinthians",
            bookNumber: 46,
            bookKo: "고린도전서",
            bookEn: "1 Corinthians",
            category: "Pauline Epistles",
            summaryKo: "분쟁과 문제가 있는 고린도 교회에 교회 질서와 사랑의 길을 가르칩니다.",
            summaryEn: "Teaches church order and the way of love to the divided and troubled Corinthian church.",
            messageKo: "은사는 다양하나 사랑 없이는 아무것도 아니며, 사랑은 모든 것을 덮습니다.",
            messageEn: "There are various gifts, but without love they are nothing; love covers all things.",
            yearWritten: 55,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "2corinthians",
            bookNumber: 47,
            bookKo: "고린도후서",
            bookEn: "2 Corinthians",
            category: "Pauline Epistles",
            summaryKo: "바울의 사도직을 변호하고, 고난 중에 역사하시는 하나님의 능력을 증거합니다.",
            summaryEn: "Defends Paul's apostleship and testifies to God's power working through suffering.",
            messageKo: "내 은혜가 네게 족하다. 이는 내 능력이 약한 데서 온전하여짐이라.",
            messageEn: "My grace is sufficient for you, for my power is made perfect in weakness.",
            yearWritten: 56,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "galatians",
            bookNumber: 48,
            bookKo: "갈라디아서",
            bookEn: "Galatians",
            category: "Pauline Epistles",
            summaryKo: "율법이 아닌 믿음으로 의롭게 되는 복음의 자유를 강력히 선포합니다.",
            summaryEn: "Strongly proclaims the freedom of the gospel: justification by faith, not by law.",
            messageKo: "그리스도께서 우리를 자유롭게 하셨으니, 다시는 종의 멍에를 메지 말라.",
            messageEn: "It is for freedom that Christ has set us free; do not be burdened again by a yoke of slavery.",
            yearWritten: 49,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "ephesians",
            bookNumber: 49,
            bookKo: "에베소서",
            bookEn: "Ephesians",
            category: "Pauline Epistles",
            summaryKo: "그리스도 안에서 교회의 정체성과 하나됨, 그리고 신자의 삶을 가르칩니다.",
            summaryEn: "Teaches the church's identity and unity in Christ, and how believers should live.",
            messageKo: "너희는 은혜로 구원을 받았으니, 이것은 하나님의 선물이라 행위에서 난 것이 아닙니다.",
            messageEn: "For it is by grace you have been saved through faith—this is the gift of God, not by works.",
            yearWritten: 60,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "philippians",
            bookNumber: 50,
            bookKo: "빌립보서",
            bookEn: "Philippians",
            category: "Pauline Epistles",
            summaryKo: "옥중에서 쓴 기쁨의 편지로, 그리스도 안에서의 참된 기쁨을 나눕니다.",
            summaryEn: "A letter of joy written from prison, sharing true joy in Christ.",
            messageKo: "나의 사는 것이 그리스도니 죽는 것도 유익함이라. 주 안에서 항상 기뻐하라.",
            messageEn: "For to me, to live is Christ and to die is gain. Rejoice in the Lord always.",
            yearWritten: 61,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "colossians",
            bookNumber: 51,
            bookKo: "골로새서",
            bookEn: "Colossians",
            category: "Pauline Epistles",
            summaryKo: "그리스도의 충만하심과 그 안에서 완전해지는 신자의 삶을 강조합니다.",
            summaryEn: "Emphasizes Christ's fullness and the believer's completeness in Him.",
            messageKo: "그리스도는 만물의 으뜸이시며, 우리는 그 안에서 충만하게 되었습니다.",
            messageEn: "Christ is supreme over all, and in Him we have been made complete.",
            yearWritten: 60,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "1thessalonians",
            bookNumber: 52,
            bookKo: "데살로니가전서",
            bookEn: "1 Thessalonians",
            category: "Pauline Epistles",
            summaryKo: "핍박 중에도 믿음을 지키는 교회를 격려하고, 주님의 재림을 가르칩니다.",
            summaryEn: "Encourages a church persevering in faith through persecution and teaches about Christ's return.",
            messageKo: "주님은 다시 오시며, 우리는 공중에서 그를 영접하여 영원히 함께 할 것입니다.",
            messageEn: "The Lord will come again, and we will meet Him in the air and be with Him forever.",
            yearWritten: 51,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "2thessalonians",
            bookNumber: 53,
            bookKo: "데살로니가후서",
            bookEn: "2 Thessalonians",
            category: "Pauline Epistles",
            summaryKo: "재림에 대한 오해를 바로잡고, 인내와 거룩한 삶을 권면합니다.",
            summaryEn: "Corrects misunderstandings about Christ's return and encourages patience and holy living.",
            messageKo: "주의 날이 올 때까지 굳건히 서서 게으르지 않게 일하며 살아야 합니다.",
            messageEn: "Stand firm until the day of the Lord and live diligently, not being idle.",
            yearWritten: 51,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "1timothy",
            bookNumber: 54,
            bookKo: "디모데전서",
            bookEn: "1 Timothy",
            category: "Pauline Epistles",
            summaryKo: "젊은 목회자 디모데에게 교회 리더십과 목회 지침을 제공합니다.",
            summaryEn: "Provides church leadership and pastoral guidance to the young pastor Timothy.",
            messageKo: "경건에 이르는 훈련이 필요하며, 네 젊음을 업신여기지 말고 본이 되라.",
            messageEn: "Train yourself in godliness; don't let anyone look down on you because you are young, but set an example.",
            yearWritten: 64,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "2timothy",
            bookNumber: 55,
            bookKo: "디모데후서",
            bookEn: "2 Timothy",
            category: "Pauline Epistles",
            summaryKo: "바울의 마지막 서신으로, 복음을 위해 고난받으며 충성하라고 권면합니다.",
            summaryEn: "Paul's final letter, encouraging faithfulness and willingness to suffer for the gospel.",
            messageKo: "나는 선한 싸움을 싸우고 달려갈 길을 마쳤으니, 의의 면류관이 예비되어 있습니다.",
            messageEn: "I have fought the good fight, I have finished the race; a crown of righteousness awaits me.",
            yearWritten: 67,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "titus",
            bookNumber: 56,
            bookKo: "디도서",
            bookEn: "Titus",
            category: "Pauline Epistles",
            summaryKo: "그레데 섬의 교회를 세우는 디도에게 교회 질서와 선한 행실을 가르칩니다.",
            summaryEn: "Teaches Titus about church order and good works as he establishes churches in Crete.",
            messageKo: "은혜는 우리를 구원하고 경건하게 살도록 훈련시켜, 선한 일에 열심이 되게 합니다.",
            messageEn: "Grace saves us and trains us to live godly lives, making us eager to do good works.",
            yearWritten: 64,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "philemon",
            bookNumber: 57,
            bookKo: "빌레몬서",
            bookEn: "Philemon",
            category: "Pauline Epistles",
            summaryKo: "도망친 노예 오네시모를 용서하고 형제로 받아달라는 개인 서신입니다.",
            summaryEn: "A personal letter asking Philemon to forgive his runaway slave Onesimus and receive him as a brother.",
            messageKo: "그리스도 안에서 우리는 모두 형제이며, 용서와 화해는 복음의 열매입니다.",
            messageEn: "In Christ we are all brothers; forgiveness and reconciliation are fruits of the gospel.",
            yearWritten: 60,
            yearEvents: nil
        ),
        
        // ============================================================
        // NEW TESTAMENT - GENERAL EPISTLES (공동서신)
        // ============================================================
        BibleBookSummary(
            id: "hebrews",
            bookNumber: 58,
            bookKo: "히브리서",
            bookEn: "Hebrews",
            category: "General Epistles",
            summaryKo: "예수 그리스도가 구약의 모든 제사와 제도보다 뛰어나심을 증명합니다.",
            summaryEn: "Demonstrates that Jesus Christ is superior to all Old Testament sacrifices and institutions.",
            messageKo: "예수님은 영원한 대제사장으로서 단번에 영원한 속죄를 이루셨습니다.",
            messageEn: "Jesus is the eternal high priest who made atonement once for all.",
            yearWritten: 65,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "james",
            bookNumber: 59,
            bookKo: "야고보서",
            bookEn: "James",
            category: "General Epistles",
            summaryKo: "행함 없는 믿음은 죽은 것임을 강조하며 실천적인 신앙을 가르칩니다.",
            summaryEn: "Emphasizes that faith without works is dead and teaches practical Christian living.",
            messageKo: "믿음은 행함으로 증명되며, 행함이 없는 믿음은 그 자체가 죽은 것입니다.",
            messageEn: "Faith is proven by actions; faith without works is dead.",
            yearWritten: 48,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "1peter",
            bookNumber: 60,
            bookKo: "베드로전서",
            bookEn: "1 Peter",
            category: "General Epistles",
            summaryKo: "핍박 중에 있는 신자들에게 소망을 주고 거룩한 삶을 권면합니다.",
            summaryEn: "Gives hope to persecuted believers and encourages holy living.",
            messageKo: "너희가 불 시험을 이상히 여기지 말고, 그리스도의 고난에 참여하는 것을 기뻐하라.",
            messageEn: "Do not be surprised at the fiery trial; rejoice in sharing Christ's sufferings.",
            yearWritten: 64,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "2peter",
            bookNumber: 61,
            bookKo: "베드로후서",
            bookEn: "2 Peter",
            category: "General Epistles",
            summaryKo: "거짓 교사들을 경계하고, 주님의 재림을 기다리며 성장하라고 권면합니다.",
            summaryEn: "Warns against false teachers and encourages growth while waiting for the Lord's return.",
            messageKo: "주께서는 약속을 더디하지 않으시며, 아무도 멸망치 않고 회개하기를 원하십니다.",
            messageEn: "The Lord is not slow in keeping His promise; He wants everyone to come to repentance.",
            yearWritten: 66,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "1john",
            bookNumber: 62,
            bookKo: "요한일서",
            bookEn: "1 John",
            category: "General Epistles",
            summaryKo: "참된 교제와 사랑, 그리고 빛 가운데 행하는 삶을 가르칩니다.",
            summaryEn: "Teaches about true fellowship, love, and walking in the light.",
            messageKo: "하나님은 사랑이시며, 사랑 안에 거하는 자는 하나님 안에 거합니다.",
            messageEn: "God is love; whoever lives in love lives in God, and God in them.",
            yearWritten: 90,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "2john",
            bookNumber: 63,
            bookKo: "요한이서",
            bookEn: "2 John",
            category: "General Epistles",
            summaryKo: "진리 안에서 걷고 거짓 교사들을 경계하라고 권면하는 짧은 서신입니다.",
            summaryEn: "A brief letter encouraging walking in truth and warning against false teachers.",
            messageKo: "진리 안에서 사랑하며 걷고, 진리를 부인하는 자를 받아들이지 말라.",
            messageEn: "Walk in truth and love, and do not welcome those who deny the truth.",
            yearWritten: 90,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "3john",
            bookNumber: 64,
            bookKo: "요한삼서",
            bookEn: "3 John",
            category: "General Epistles",
            summaryKo: "선을 행하는 가이오를 칭찬하고, 교만한 디오드레베를 경계합니다.",
            summaryEn: "Commends Gaius for doing good and warns against the arrogant Diotrephes.",
            messageKo: "선을 행하는 자는 하나님께 속하고, 악을 행하는 자는 하나님을 뵈온 적이 없습니다.",
            messageEn: "Whoever does good is from God; whoever does evil has not seen God.",
            yearWritten: 90,
            yearEvents: nil
        ),
        BibleBookSummary(
            id: "jude",
            bookNumber: 65,
            bookKo: "유다서",
            bookEn: "Jude",
            category: "General Epistles",
            summaryKo: "교회에 침투한 거짓 교사들을 폭로하고 믿음을 위해 싸우라고 권면합니다.",
            summaryEn: "Exposes false teachers infiltrating the church and urges believers to contend for the faith.",
            messageKo: "성도에게 단번에 주신 믿음을 위하여 힘써 싸우라.",
            messageEn: "Contend earnestly for the faith once delivered to the saints.",
            yearWritten: 68,
            yearEvents: nil
        ),
        
        // ============================================================
        // NEW TESTAMENT - PROPHECY (예언서)
        // ============================================================
        BibleBookSummary(
            id: "revelation",
            bookNumber: 66,
            bookKo: "요한계시록",
            bookEn: "Revelation",
            category: "Prophecy",
            summaryKo: "고난받는 교회들에게 주시는 소망의 환상이며, 악의 패배와 새 하늘 새 땅의 도래를 예고합니다.",
            summaryEn: "A vision of hope for suffering churches, foretelling the defeat of evil and the coming of a new heaven and earth.",
            messageKo: "최후의 승리는 하나님께 있으며, 주님은 반드시 다시 오셔서 모든 눈물을 닦아주실 것입니다.",
            messageEn: "The ultimate victory belongs to God, and He will surely return to wipe away every tear.",
            yearWritten: 95,
            yearEvents: nil
        )
    ]
    
    // MARK: - Helper Methods
    
    /// Get summary by book ID (string, matches BibleBook.id)
    static func summary(for bookId: String) -> BibleBookSummary? {
        return all.first { $0.id == bookId }
    }
    
    /// Get summary by book number (1-66, matches API and BibleBook.order)
    static func summary(forBookNumber bookNumber: Int) -> BibleBookSummary? {
        return all.first { $0.bookNumber == bookNumber }
    }
    
    /// Get summaries by category
    static func summaries(for category: String) -> [BibleBookSummary] {
        return all.filter { $0.category == category }
    }
    
    /// Get all categories
    static var categories: [String] {
        return Array(Set(all.map { $0.category })).sorted()
    }
    
    /// Get summaries sorted by timeline (oldest events first)
    static var timelineSorted: [BibleBookSummary] {
        return all.sorted { (a, b) -> Bool in
            let yearA = a.yearEvents ?? a.yearWritten
            let yearB = b.yearEvents ?? b.yearWritten
            return yearA < yearB
        }
    }
    
    /// Get summaries sorted by canonical order (1-66)
    static var canonicalSorted: [BibleBookSummary] {
        return all.sorted { $0.bookNumber < $1.bookNumber }
    }
}
