import SwiftUI

struct ContentView: View {

    @StateObject private var slotManager = SlotManager()
    @StateObject private var countryManager = CountryManager()
    @AppStorage("onboarding_done") private var onboardingDone = false

    var body: some View {
        if onboardingDone && countryManager.selectedCountry != nil {
            MainView(slotManager: slotManager, countryManager: countryManager)
                .task { await slotManager.refreshStatuses() }
        } else {
            OnboardingView(
                countryManager: countryManager,
                slotManager: slotManager
            ) {
                onboardingDone = true
            }
        }
    }
}
