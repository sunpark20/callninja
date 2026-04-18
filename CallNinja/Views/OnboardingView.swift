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
            .navigationTitle("콜닌자 설정")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Country Selection

    private var countrySelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("사용할 나라를 선택하세요")
                .font(.title2.bold())

            Text("선택한 나라의 전화번호 형식에 맞게\n차단 범위가 자동 계산됩니다.")
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
                            Text(country.name)
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
                Button("나라 선택") {
                    showCountryPicker = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()

            if countryManager.selectedCountry != nil {
                Button("다음") {
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
                    Text("설정에서 10개 항목을 켜주세요")
                        .font(.headline)

                    if #available(iOS 18, *) {
                        Text("설정 > 앱 > 전화 > 차단 및 발신자 확인")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("설정 > 전화 > 차단 및 발신자 확인")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("설정 열기") {
                    openCallBlockingSettings()
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Spacer()
                    Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) 활성화")
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
                    Button("시작하기") {
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
        let candidates = [
            "App-prefs:Phone&path=CALL_BLOCKING_AND_IDENTIFICATION",
            "App-prefs:Phone",
            "App-prefs:"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
            List(filtered) { country in
                Button {
                    onSelect(country)
                } label: {
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                        Spacer()
                        Text(country.dialCode)
                            .foregroundStyle(.secondary)
                        if country.iso == selected?.iso {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "나라 검색")
            .navigationTitle("나라 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
