import SwiftUI

enum SheetType: Identifiable {
    case numberInput(slotIndex: Int)
    case slotDetail(slotIndex: Int)

    var id: String {
        switch self {
        case .numberInput(let i): return "input-\(i)"
        case .slotDetail(let i): return "detail-\(i)"
        }
    }
}

struct MainView: View {

    @ObservedObject var slotManager: SlotManager
    @ObservedObject var countryManager: CountryManager

    @State private var activeSheet: SheetType?
    @State private var showCountryChange = false

    var body: some View {
        NavigationStack {
            List {
                statusSection
                slotListSection
                infoSection
            }
            .navigationTitle(String(localized: "main.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("main.changeCountry") { showCountryChange = true }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .numberInput(let index):
                    if let country = countryManager.selectedCountry {
                        NumberInputView(
                            country: country,
                            existingPrefixes: slotManager.existingPrefixes,
                            currentInput: slotManager.slots[index].inputNumber
                        ) { result, inputNumber in
                            slotManager.setSlot(index, result: result, inputNumber: inputNumber)
                            activeSheet = nil
                            Task { await slotManager.reloadSlot(index) }
                        }
                    }
                case .slotDetail(let index):
                    SlotDetailView(
                        slot: slotManager.slots[index],
                        onDelete: {
                            slotManager.clearSlot(index)
                            activeSheet = nil
                            Task { await slotManager.reloadSlot(index) }
                        },
                        onChange: {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                activeSheet = .numberInput(slotIndex: index)
                            }
                        }
                    )
                }
            }
            .alert(String(localized: "main.changeCountryAlert"), isPresented: $showCountryChange) {
                Button("main.change", role: .destructive) {
                    slotManager.clearAllSlots()
                    countryManager.clearSelection()
                    UserDefaults.standard.set(false, forKey: "onboarding_done")
                }
                Button("main.cancel", role: .cancel) {}
            } message: {
                Text("main.changeCountryMessage")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task { await slotManager.refreshStatuses() }
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            if let country = countryManager.selectedCountry {
                HStack {
                    Text("\(country.flag) \(country.displayName)")
                    Spacer()
                    if slotManager.enabledCount < SlotManager.slotCount {
                        Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) \(String(localized: "onboarding.activated"))")
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) \(String(localized: "onboarding.activated"))")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    private var slotListSection: some View {
        Section(String(localized: "main.slotsSection")) {
            ForEach(slotManager.orderedSlots) { slot in
                SlotRowView(
                    slot: slot,
                    error: slotManager.slotErrors[slot.id],
                    isReloading: slotManager.reloadingSlot == slot.id,
                    onTap: {
                        if slot.isEmpty {
                            activeSheet = .numberInput(slotIndex: slot.id)
                        } else {
                            activeSheet = .slotDetail(slotIndex: slot.id)
                        }
                    },
                    onToggle: {
                        slotManager.toggleSlot(slot.id)
                        Task { await slotManager.reloadSlot(slot.id) }
                    }
                )
            }
            .onMove { source, destination in
                var order = slotManager.slotOrder
                order.move(fromOffsets: source, toOffset: destination)
                slotManager.reorderSlots(order)
            }
        }
    }

    private var infoSection: some View {
        Section {
            Text("main.contactsNote")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Slot Detail

struct SlotDetailView: View {
    let slot: BlockSlot
    let onDelete: () -> Void
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(slot.displayPattern ?? "")
                        .font(.title2.monospaced())
                }

                if let start = slot.rangeStart, let end = slot.rangeEnd {
                    Section(String(localized: "slotDetail.range")) {
                        Text("\(start) ~ \(end)")
                            .font(.caption.monospaced())
                        Text("slotDetail.total")
                    }
                }

                if let input = slot.inputNumber {
                    Section(String(localized: "slotDetail.originalNumber")) {
                        Text(input)
                    }
                }

                Section {
                    Button("slotDetail.changeNumber") { onChange() }
                    Button("slotDetail.delete", role: .destructive) { onDelete() }
                }
            }
            .navigationTitle(String(localized: "slotDetail.title \(slot.id + 1)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("slotDetail.close") { dismiss() }
                }
            }
        }
    }
}
