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
            case 0: return ("unknown", "알 수 없는 오류. 기기를 재시작해 보세요.")
            case 1: return ("noExtensionFound", "익스텐션을 찾을 수 없음. 앱을 재설치해 주세요.")
            case 2: return ("loadingInterrupted", "로딩 중단됨. 다시 시도해 주세요.")
            case 3: return ("entriesOutOfOrder", "내부 오류 (번호 순서). 개발자에게 문의해 주세요.")
            case 4: return ("duplicateEntries", "내부 오류 (중복). 개발자에게 문의해 주세요.")
            case 5: return ("maximumEntriesExceeded", "등록 한도 초과. 개발자에게 문의해 주세요.")
            case 6: return ("extensionDisabled", "설정에서 꺼져 있습니다. 설정에서 켜주세요.")
            case 7: return ("currentlyLoading", "이미 로딩 중. 잠시 후 다시 시도해 주세요.")
            case 8: return ("unexpectedIncrementalRemoval", "설정에서 OFF→ON 후 다시 시도해 주세요.")
            default: return ("code\(nsError.code)", "오류 코드 \(nsError.code). 기기를 재시작해 보세요.")
            }
        }

        if nsError.domain == "com.apple.callkit.database.sqlite" {
            if nsError.code == 19 {
                return ("sqlite:19", "DB 충돌. 앱 삭제 → 기기 재시작 → 앱 재설치 후 다시 시도해 주세요.")
            }
            return ("sqlite:\(nsError.code)", "DB 오류. 앱 삭제 → 기기 재시작 → 앱 재설치 후 다시 시도해 주세요.")
        }

        return ("other:\(nsError.code)", "\(nsError.domain):\(nsError.code) — 기기를 재시작해 보세요.")
    }
}

enum SlotError {
    case reloadFailed(code: String, message: String)
    case extensionDisabled
    case appGroupFailure
}
