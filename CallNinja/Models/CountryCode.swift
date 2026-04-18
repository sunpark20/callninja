import Foundation

struct CountryCode: Codable, Identifiable, Hashable {
    let name: String
    let nameEn: String
    let code: Int
    let iso: String
    let flag: String
    let stripLeadingZero: Bool
    let minLocalDigits: Int
    let maxLocalDigits: Int

    var id: String { iso }

    var dialCode: String { "+\(code)" }

    var displayName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return lang == "ko" ? name : nameEn
    }

    static func loadAll() -> [CountryCode] {
        guard let url = Bundle.main.url(forResource: "country_codes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let codes = try? JSONDecoder().decode([CountryCode].self, from: data) else {
            return []
        }
        return codes
    }
}
