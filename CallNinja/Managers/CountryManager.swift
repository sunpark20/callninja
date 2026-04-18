import Foundation

@MainActor
final class CountryManager: ObservableObject {

    @Published var selectedCountry: CountryCode?
    @Published var allCountries: [CountryCode] = []

    private let selectedKey = "selected_country_iso"

    init() {
        allCountries = CountryCode.loadAll()
        if let iso = UserDefaults.standard.string(forKey: selectedKey) {
            selectedCountry = allCountries.first { $0.iso == iso }
        }
    }

    func select(_ country: CountryCode) {
        selectedCountry = country
        UserDefaults.standard.set(country.iso, forKey: selectedKey)
    }

    func clearSelection() {
        selectedCountry = nil
        UserDefaults.standard.removeObject(forKey: selectedKey)
    }
}
