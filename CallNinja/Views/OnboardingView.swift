import SwiftUI
import CallKit

struct OnboardingView: View {

    @ObservedObject var countryManager: CountryManager
    @ObservedObject var slotManager: SlotManager
    let onComplete: () -> Void

    @State private var searchText = ""
    @State private var showCountryPicker = false
    @State private var phase: OnboardingPhase = .country

    enum OnboardingPhase {
        case country
        case extensions
    }

    private var allEnabled: Bool {
        slotManager.statusChecked && slotManager.enabledCount == SlotManager.slotCount
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if phase == .country {
                    countrySelectionView
                } else {
                    extensionActivationView
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Country Selection

    private var countrySelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("onboarding.selectCountry")
                .font(.title2.bold())

            Text("onboarding.selectCountryDesc")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let country = countryManager.selectedCountry {
                Button {
                    showCountryPicker = true
                } label: {
                    HStack {
                        Text(country.flag)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(country.displayName)
                                .font(.headline)
                            Text(country.dialCode)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button("onboarding.selectCountryButton") {
                    showCountryPicker = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()

            if countryManager.selectedCountry != nil {
                Button("onboarding.next") {
                    phase = .extensions
                    Task { await slotManager.refreshStatuses() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(
                countries: countryManager.allCountries,
                selected: countryManager.selectedCountry
            ) { country in
                countryManager.select(country)
                showCountryPicker = false
            }
        }
    }

    // MARK: - Extension Activation

    private var extensionActivationView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("onboarding.enableExtensions")
                        .font(.headline)

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("onboarding.settingsPath.ipad")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if #available(iOS 18, *) {
                        Text("onboarding.settingsPath.ios18")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("onboarding.settingsPath.legacy")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("onboarding.openSettings") {
                    openCallBlockingSettings()
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Spacer()
                    Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) \(String(localized: "onboarding.activated"))")
                        .monospacedDigit()
                        .font(.title3.bold())
                    if allEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            if allEnabled {
                Section {
                    Button("onboarding.start") {
                        UserDefaults.standard.set(true, forKey: "onboarding_done")
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await slotManager.refreshStatuses() }
        }
    }

    private func openCallBlockingSettings() {
        let candidates: [String]

        if UIDevice.current.userInterfaceIdiom == .pad {
            candidates = [
                "App-prefs:com.callninja.app",
                "App-prefs:",
            ]
        } else {
            candidates = [
                "App-prefs:com.apple.mobilephone&path=CALL_BLOCKING_AND_IDENTIFICATION",
                "App-prefs:com.apple.mobilephone",
                "prefs:root=Apps&path=com.apple.mobilephone",
                "App-prefs:Phone&path=CALL_BLOCKING_AND_IDENTIFICATION",
                "App-prefs:Phone",
                "prefs:root=Phone",
            ]
        }

        for urlString in candidates {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url) { success in
                    if success { return }
                }
                return
            }
        }
    }
}

// MARK: - Country Picker

struct CountryPickerView: View {
    let countries: [CountryCode]
    let selected: CountryCode?
    let onSelect: (CountryCode) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: [CountryCode] {
        guard !searchText.isEmpty else { return countries }
        let query = searchText.lowercased()
        return countries.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.nameEn.lowercased().contains(query) ||
            $0.dialCode.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { country in
                        Button {
                            onSelect(country)
                        } label: {
                            HStack {
                                Text(country.flag)
                                Text(country.displayName)
                                Spacer()
                                Text(country.dialCode)
                                    .foregroundStyle(.secondary)
                                if country.iso == selected?.iso {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 16)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: Text("countryPicker.search"))
            .navigationTitle(String(localized: "countryPicker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("countryPicker.close") { dismiss() }
                }
            }
        }
    }
}
