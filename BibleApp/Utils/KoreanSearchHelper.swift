import Foundation

/// 한글 초성/부분 검색 헬퍼
enum KoreanSearchHelper {
    
    // MARK: - Constants
    
    /// 한글 초성 목록 (19개)
    private static let choseongList: [Character] = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ",
        "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    /// 한글 완성형 시작 (가 = U+AC00)
    private static let hangulBase: UInt32 = 0xAC00
    
    /// 한글 완성형 끝 (힣 = U+D7A3)
    private static let hangulEnd: UInt32 = 0xD7A3
    
    /// 초성 단위 (21 중성 × 28 종성 = 588)
    private static let choseongUnit: UInt32 = 588
    
    /// 중성 단위 (28 종성)
    private static let jungseongUnit: UInt32 = 28
    
    // MARK: - Public Methods
    
    /// 검색어가 대상 문자열과 매칭되는지 확인 (초성/부분 검색 지원)
    /// - Parameters:
    ///   - query: 검색어 (예: "ㅊ", "차", "창세")
    ///   - target: 대상 문자열 (예: "창세기")
    /// - Returns: 매칭 여부
    static func matches(query: String, target: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return true }
        
        // 1. 기본 포함 검색
        if target.contains(trimmedQuery) {
            return true
        }
        
        // 2. 검색어가 순수 초성인 경우 (예: "ㅊ", "ㅊㅅ")
        if isAllChoseong(trimmedQuery) {
            let targetChoseong = extractChoseong(from: target)
            return targetChoseong.contains(trimmedQuery)
        }
        
        // 3. 부분 음절 검색 (예: "차" -> "창세기")
        // 마지막 글자가 종성이 없는 완성형인 경우, 해당 음절로 시작하는 글자와 매칭
        return matchesWithPartialSyllable(query: trimmedQuery, target: target)
    }
    
    /// 문자열에서 초성만 추출
    /// - Parameter text: 한글 문자열
    /// - Returns: 초성만 포함된 문자열
    static func extractChoseong(from text: String) -> String {
        var result = ""
        for char in text {
            if let choseong = getChoseong(from: char) {
                result.append(choseong)
            }
        }
        return result
    }
    
    // MARK: - Private Methods
    
    /// 문자가 초성인지 확인
    private static func isChoseong(_ char: Character) -> Bool {
        choseongList.contains(char)
    }
    
    /// 문자열이 모두 초성인지 확인
    private static func isAllChoseong(_ text: String) -> Bool {
        !text.isEmpty && text.allSatisfy { isChoseong($0) }
    }
    
    /// 완성형 한글에서 초성 추출
    private static func getChoseong(from char: Character) -> Character? {
        guard let scalar = char.unicodeScalars.first else { return nil }
        let value = scalar.value
        
        // 이미 초성인 경우 그대로 반환
        if isChoseong(char) {
            return char
        }
        
        // 완성형 한글인 경우
        if value >= hangulBase && value <= hangulEnd {
            let index = Int((value - hangulBase) / choseongUnit)
            if index < choseongList.count {
                return choseongList[index]
            }
        }
        
        return nil
    }
    
    /// 완성형 한글의 종성 인덱스 반환 (0이면 종성 없음)
    private static func getJongseongIndex(from char: Character) -> Int? {
        guard let scalar = char.unicodeScalars.first else { return nil }
        let value = scalar.value
        
        if value >= hangulBase && value <= hangulEnd {
            return Int((value - hangulBase) % jungseongUnit)
        }
        return nil
    }
    
    /// 부분 음절 검색
    /// 예: "차" (종성 없음) -> "창", "참", "찬" 등과 매칭
    private static func matchesWithPartialSyllable(query: String, target: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let queryChars = Array(query)
        let targetChars = Array(target)
        
        // 타겟에서 매칭 시작 위치 찾기
        for startIndex in 0..<targetChars.count {
            if matchesFrom(queryChars: queryChars, targetChars: targetChars, startIndex: startIndex) {
                return true
            }
        }
        
        return false
    }
    
    /// 특정 위치부터 매칭 확인
    private static func matchesFrom(queryChars: [Character], targetChars: [Character], startIndex: Int) -> Bool {
        guard startIndex + queryChars.count <= targetChars.count else { return false }
        
        for (i, queryChar) in queryChars.enumerated() {
            let targetChar = targetChars[startIndex + i]
            let isLastQueryChar = (i == queryChars.count - 1)
            
            if isLastQueryChar {
                // 마지막 검색 문자: 부분 매칭 허용
                if !matchesSyllable(query: queryChar, target: targetChar, allowPartial: true) {
                    return false
                }
            } else {
                // 중간 문자: 정확히 일치해야 함
                if queryChar != targetChar {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// 단일 음절 매칭
    /// allowPartial이 true이면 "차" -> "창" 같은 부분 매칭 허용
    private static func matchesSyllable(query: Character, target: Character, allowPartial: Bool) -> Bool {
        // 완전 일치
        if query == target {
            return true
        }
        
        // 초성으로 검색하는 경우
        if isChoseong(query) {
            if let targetChoseong = getChoseong(from: target) {
                return query == targetChoseong
            }
            return false
        }
        
        // 부분 매칭 (종성 없는 완성형으로 검색)
        if allowPartial {
            guard let queryScalar = query.unicodeScalars.first,
                  let targetScalar = target.unicodeScalars.first else {
                return false
            }
            
            let queryValue = queryScalar.value
            let targetValue = targetScalar.value
            
            // 둘 다 완성형 한글인 경우
            if queryValue >= hangulBase && queryValue <= hangulEnd &&
               targetValue >= hangulBase && targetValue <= hangulEnd {
                
                // 검색어의 종성 확인
                let queryJongseong = Int((queryValue - hangulBase) % jungseongUnit)
                
                // 검색어에 종성이 없는 경우, 초성+중성만 비교
                if queryJongseong == 0 {
                    // 종성을 제외한 부분이 같은지 확인
                    let queryBase = queryValue - hangulBase
                    let targetBase = targetValue - hangulBase
                    
                    let queryWithoutJong = queryBase / jungseongUnit * jungseongUnit + (queryBase % choseongUnit) / jungseongUnit * jungseongUnit
                    let targetWithoutJong = targetBase / jungseongUnit * jungseongUnit
                    
                    // 더 간단한 비교: 같은 초성+중성을 공유하는지
                    let querySyllableBase = (queryValue - hangulBase) / jungseongUnit
                    let targetSyllableBase = (targetValue - hangulBase) / jungseongUnit
                    
                    return querySyllableBase == targetSyllableBase
                }
            }
        }
        
        return false
    }
}
