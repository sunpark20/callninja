import Foundation
import CallKit

@MainActor
final class SlotManager: ObservableObject {

    static let slotCount = 10
    static let appGroupID = "group.com.callninja.shared"
    private static let bundlePrefix = "com.callninja.app.NinjaBlock"

    @Published var slots: [BlockSlot] = (0..<10).map { BlockSlot(id: $0, isEnabled: false) }
    @Published var enabledCount = 0
    @Published var statusChecked = false
    @Published var reloadingSlot: Int?
    @Published var slotErrors: [Int: SlotError] = [:]
    @Published var slotOrder: [Int] = Array(0..<10)

    private let appGroupDefaults: UserDefaults?
    private let localDefaults = UserDefaults.standard

    var orderedSlots: [BlockSlot] {
        slotOrder.compactMap { index in
            slots.indices.contains(index) ? slots[index] : nil
        }
    }

    init() {
        appGroupDefaults = UserDefaults(suiteName: Self.appGroupID)
        loadSlots()
        loadOrder()
    }

    // MARK: - Status

    func refreshStatuses() async {
        var count = 0
        for i in 0..<Self.slotCount {
            let bundleID = Self.bundleID(for: i)
            do {
                let status = try await CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: bundleID)
                if status == .enabled { count += 1 }
            } catch {
                // 무시
            }
        }
        enabledCount = count
        statusChecked = true
    }

    // MARK: - Reload

    func reloadSlot(_ index: Int) async {
        guard reloadingSlot == nil else { return }
        reloadingSlot = index
        slotErrors[index] = nil

        saveSlotToAppGroup(index)

        let bundleID = Self.bundleID(for: index)
        do {
            try await CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: bundleID)
        } catch {
            let (code, message) = Self.describeError(error)
            slotErrors[index] = .reloadFailed(code: code, message: message)
        }

        reloadingSlot = nil
    }

    // MARK: - Slot Data

    func setSlot(_ index: Int, result: E164Result, inputNumber: String) {
        slots[index].prefix = result.prefix
        slots[index].isEnabled = true
        slots[index].displayPattern = result.displayPattern
        slots[index].inputNumber = inputNumber
        saveSlotToLocal(index)
        saveSlotToAppGroup(index)
    }

    func clearSlot(_ index: Int) {
        slots[index].prefix = nil
        slots[index].isEnabled = false
        slots[index].displayPattern = nil
        slots[index].inputNumber = nil
        slotErrors[index] = nil
        saveSlotToLocal(index)
        saveSlotToAppGroup(index)
    }

    func toggleSlot(_ index: Int) {
        guard slots[index].prefix != nil else { return }
        slots[index].isEnabled.toggle()
        saveSlotToLocal(index)
        saveSlotToAppGroup(index)
    }

    func clearAllSlots() {
        for i in 0..<Self.slotCount {
            clearSlot(i)
        }
    }

    func reorderSlots(_ newOrder: [Int]) {
        slotOrder = newOrder
        localDefaults.set(newOrder, forKey: "slot_order")
    }

    var existingPrefixes: [Int64?] {
        slots.map { $0.prefix }
    }

    // MARK: - Persistence

    private func saveSlotToAppGroup(_ index: Int) {
        guard let defaults = appGroupDefaults else { return }
        let slot = slots[index]

        if let prefix = slot.prefix {
            defaults.set(Int(prefix), forKey: "slot_\(index)_prefix")
        } else {
            defaults.removeObject(forKey: "slot_\(index)_prefix")
        }
        defaults.set(slot.isEnabled, forKey: "slot_\(index)_enabled")
        defaults.synchronize()
    }

    private func saveSlotToLocal(_ index: Int) {
        let slot = slots[index]
        localDefaults.set(slot.displayPattern, forKey: "slot_\(index)_display")
        localDefaults.set(slot.inputNumber, forKey: "slot_\(index)_input")
        if let prefix = slot.prefix {
            localDefaults.set(Int(prefix), forKey: "slot_\(index)_prefix_local")
        } else {
            localDefaults.removeObject(forKey: "slot_\(index)_prefix_local")
        }
        localDefaults.set(slot.isEnabled, forKey: "slot_\(index)_enabled_local")
    }

    private func loadSlots() {
        for i in 0..<Self.slotCount {
            let prefixVal = localDefaults.object(forKey: "slot_\(i)_prefix_local") as? Int
            slots[i].prefix = prefixVal.map { Int64($0) }
            slots[i].isEnabled = localDefaults.bool(forKey: "slot_\(i)_enabled_local")
            slots[i].displayPattern = localDefaults.string(forKey: "slot_\(i)_display")
            slots[i].inputNumber = localDefaults.string(forKey: "slot_\(i)_input")
        }
    }

    private func loadOrder() {
        if let order = localDefaults.array(forKey: "slot_order") as? [Int], order.count == Self.slotCount {
            slotOrder = order
        }
    }

    // MARK: - Helpers

    private static func bundleID(for index: Int) -> String {
        "\(bundlePrefix)\(String(format: "%02d", index))"
    }

    static func describeError(_ error: Error) -> (code: String, message: String) {
        let nsError = error as NSError

        if nsError.domain == "com.apple.CallKit.error.calldirectorymanager" {
            switch nsError.code {
            case 0: return ("unknown", String(localized: "error.unknown"))
            case 1: return ("noExtensionFound", String(localized: "error.noExtensionFound"))
            case 2: return ("loadingInterrupted", String(localized: "error.loadingInterrupted"))
            case 3: return ("entriesOutOfOrder", String(localized: "error.entriesOutOfOrder"))
            case 4: return ("duplicateEntries", String(localized: "error.duplicateEntries"))
            case 5: return ("maximumEntriesExceeded", String(localized: "error.maximumEntriesExceeded"))
            case 6: return ("extensionDisabled", String(localized: "error.extensionDisabled"))
            case 7: return ("currentlyLoading", String(localized: "error.currentlyLoading"))
            case 8: return ("unexpectedIncrementalRemoval", String(localized: "error.unexpectedIncrementalRemoval"))
            default: return ("code\(nsError.code)", String(localized: "error.codeN \(nsError.code)"))
            }
        }

        if nsError.domain == "com.apple.callkit.database.sqlite" {
            if nsError.code == 19 {
                return ("sqlite:19", String(localized: "error.sqlite19"))
            }
            return ("sqlite:\(nsError.code)", String(localized: "error.sqliteN"))
        }

        return ("other:\(nsError.code)", String(localized: "error.other \(nsError.domain) \(nsError.code)"))
    }
}

enum SlotError {
    case reloadFailed(code: String, message: String)
    case extensionDisabled
    case appGroupFailure
}
