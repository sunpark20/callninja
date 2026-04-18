import Foundation

struct E164Result {
    let prefix: Int64
    let rangeStart: Int64
    let rangeEnd: Int64
    let count: Int
    let displayPattern: String
    let localPrefix: String
}

enum E164Error: Error, LocalizedError {
    case empty
    case tooShort(current: Int, minimum: Int)
    case tooLong(current: Int, maximum: Int)
    case invalidNumber
    case duplicatePrefix(slotIndex: Int)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "번호를 입력해 주세요"
        case .tooShort(let current, _):
            return "번호를 끝까지 입력해 주세요 (\(current)자리 입력됨)"
        case .tooLong(let current, let maximum):
            return "번호가 너무 깁니다 (최대 \(maximum)자리)"
        case .invalidNumber:
            return "유효하지 않은 번호입니다"
        case .duplicatePrefix(let slot):
            return "슬롯 \(slot + 1)에 이미 같은 범위가 등록되어 있습니다"
        }
    }
}

enum E164Converter {

    static let wildcardCount = 6
    static let divisor: Int64 = 1_000_000

    static func convert(
        input: String,
        country: CountryCode,
        existingPrefixes: [Int64?]
    ) -> Result<E164Result, E164Error> {
        let hadPlus = input.contains("+")
        var digits = input.filter { $0.isNumber }

        guard !digits.isEmpty else { return .failure(.empty) }

        // + 기호가 있었으면 국가코드 제거 시도
        let codeStr = String(country.code)
        if hadPlus && digits.hasPrefix(codeStr) {
            digits = String(digits.dropFirst(codeStr.count))
        }

        // 로컬 번호 자릿수 검증
        let localDigitCount = digits.count
        if localDigitCount < country.minLocalDigits {
            return .failure(.tooShort(current: localDigitCount, minimum: country.minLocalDigits))
        }
        if localDigitCount > country.maxLocalDigits {
            return .failure(.tooLong(current: localDigitCount, maximum: country.maxLocalDigits))
        }

        // 표시용 로컬 번호 보존 (0 제거 전)
        let localDigitsForDisplay = digits

        // stripLeadingZero 적용
        if country.stripLeadingZero && digits.hasPrefix("0") {
            digits = String(digits.dropFirst())
        }

        // E.164 생성
        let e164String = codeStr + digits
        let e164Length = e164String.count

        if e164Length < 8 {
            return .failure(.tooShort(current: localDigitCount, minimum: country.minLocalDigits))
        }
        if e164Length > 15 {
            return .failure(.tooLong(current: localDigitCount, maximum: country.maxLocalDigits))
        }

        guard let e164 = Int64(e164String) else {
            return .failure(.invalidNumber)
        }

        let prefix = e164 / divisor
        let rangeStart = prefix * divisor
        let rangeEnd = rangeStart + divisor - 1

        // 중복 체크
        if let dupIndex = existingPrefixes.firstIndex(where: { $0 == prefix }) {
            return .failure(.duplicatePrefix(slotIndex: dupIndex))
        }

        let displayPattern = formatLocalPattern(
            localDigits: localDigitsForDisplay,
            country: country
        )

        let prefixDigitCount = localDigitsForDisplay.count - wildcardCount
        let localPrefix = String(localDigitsForDisplay.prefix(max(0, prefixDigitCount)))

        return .success(E164Result(
            prefix: prefix,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            count: Int(divisor),
            displayPattern: displayPattern,
            localPrefix: localPrefix
        ))
    }

    static func formatLocalPattern(localDigits: String, country: CountryCode) -> String {
        let total = localDigits.count
        let prefixLen = total - wildcardCount

        guard prefixLen > 0 else { return String(repeating: "X", count: total) }

        let prefixPart = String(localDigits.prefix(prefixLen))
        let combined = prefixPart + String(repeating: "X", count: wildcardCount)

        return applyFormat(digits: combined, country: country)
    }

    private static func applyFormat(digits: String, country: CountryCode) -> String {
        let len = digits.count

        if country.iso == "KR" {
            return formatKorean(digits: digits, length: len)
        }
        if country.iso == "US" || country.iso == "CA" {
            return formatGrouped(digits: digits, groups: [3, 3, 4])
        }

        // fallback: 길이 기반 그룹핑
        switch len {
        case ...8:  return formatGrouped(digits: digits, groups: [4, 4])
        case 9:     return formatGrouped(digits: digits, groups: [3, 3, 3])
        case 10:    return formatGrouped(digits: digits, groups: [3, 3, 4])
        case 11:    return formatGrouped(digits: digits, groups: [3, 4, 4])
        default:    return formatGrouped(digits: digits, groups: [4, 4, 4])
        }
    }

    private static func formatKorean(digits: String, length: Int) -> String {
        if digits.hasPrefix("02") {
            switch length {
            case 9:  return formatGrouped(digits: digits, groups: [2, 3, 4])
            default: return formatGrouped(digits: digits, groups: [2, 4, 4])
            }
        }
        switch length {
        case 10: return formatGrouped(digits: digits, groups: [3, 3, 4])
        default: return formatGrouped(digits: digits, groups: [3, 4, 4])
        }
    }

    private static func formatGrouped(digits: String, groups: [Int]) -> String {
        var result: [String] = []
        var index = digits.startIndex
        for groupSize in groups {
            let end = digits.index(index, offsetBy: min(groupSize, digits.distance(from: index, to: digits.endIndex)))
            result.append(String(digits[index..<end]))
            index = end
            if index == digits.endIndex { break }
        }
        if index < digits.endIndex {
            result.append(String(digits[index...]))
        }
        return result.joined(separator: "-")
    }
}
