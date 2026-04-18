import Foundation

struct BlockSlot: Identifiable {
    let id: Int
    var prefix: Int64?
    var isEnabled: Bool
    var displayPattern: String?
    var inputNumber: String?

    var isEmpty: Bool { prefix == nil }

    var rangeStart: Int64? {
        guard let prefix else { return nil }
        return prefix * 1_000_000
    }

    var rangeEnd: Int64? {
        guard let prefix else { return nil }
        return prefix * 1_000_000 + 999_999
    }
}
