import SwiftUI

struct MainView: View {

    @ObservedObject var slotManager: SlotManager
    @ObservedObject var countryManager: CountryManager

    @State private var selectedSlotIndex: Int?
    @State private var showNumberInput = false
    @State private var showSlotDetail = false
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
            .sheet(isPresented: $showNumberInput) {
                if let index = selectedSlotIndex, let country = countryManager.selectedCountry {
                    NumberInputView(
                        country: country,
                        existingPrefixes: slotManager.existingPrefixes,
                        currentInput: slotManager.slots[index].inputNumber
                    ) { result, inputNumber in
                        slotManager.setSlot(index, result: result, inputNumber: inputNumber)
                        showNumberInput = false
                        Task { await slotManager.reloadSlot(index) }
                    }
                }
            }
            .sheet(isPresented: $showSlotDetail) {
                if let index = selectedSlotIndex {
                    SlotDetailView(
                        slot: slotManager.slots[index],
                        onDelete: {
                            slotManager.clearSlot(index)
                            showSlotDetail = false
                            Task { await slotManager.reloadSlot(index) }
                        },
                        onChange: {
                            showSlotDetail = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showNumberInput = true
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
                    Text("\(country.flag) \(country.name)")
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
                        selectedSlotIndex = slot.id
                        if slot.isEmpty {
                            showNumberInput = true
                        } else {
                            showSlotDetail = true
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
