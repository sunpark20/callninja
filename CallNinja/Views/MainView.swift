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
            .navigationTitle("콜닌자")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("나라 변경") { showCountryChange = true }
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
            .alert("나라를 변경하시겠습니까?", isPresented: $showCountryChange) {
                Button("변경", role: .destructive) {
                    slotManager.clearAllSlots()
                    countryManager.clearSelection()
                    UserDefaults.standard.set(false, forKey: "onboarding_done")
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("나라를 변경하면 모든 차단 설정이 초기화됩니다.")
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
                        Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) 활성화")
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(slotManager.enabledCount)/\(SlotManager.slotCount) 활성화")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    private var slotListSection: some View {
        Section("차단 슬롯") {
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
            Text("연락처에 저장된 번호는 차단되지 않습니다.")
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
                    Section("차단 범위") {
                        Text("\(start) ~ \(end)")
                            .font(.caption.monospaced())
                        Text("총 1,000,000개")
                    }
                }

                if let input = slot.inputNumber {
                    Section("원본 번호") {
                        Text(input)
                    }
                }

                Section {
                    Button("번호 변경") { onChange() }
                    Button("삭제", role: .destructive) { onDelete() }
                }
            }
            .navigationTitle("슬롯 \(slot.id + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
