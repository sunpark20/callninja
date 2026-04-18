import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    private static let appGroupID = "group.com.callninja.shared"
    private static let blockCount: CXCallDirectoryPhoneNumber = 1_000_000

    private var slotIndex: Int? {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let last = bundleID.split(separator: ".").last else { return nil }
        return Int(last.replacingOccurrences(of: "NinjaBlock", with: ""))
    }

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        guard let index = slotIndex else {
            context.cancelRequest(withError: NSError(domain: "CallDirectoryHandler", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Bundle ID parsing failed"]))
            return
        }

        if !context.isIncremental {
            context.completeRequest()
            return
        }

        context.removeAllBlockingEntries()

        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            context.cancelRequest(withError: NSError(domain: "CallDirectoryHandler", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "App Group access failed"]))
            return
        }

        let prefixKey = "slot_\(index)_prefix"
        let enabledKey = "slot_\(index)_enabled"

        let enabled = defaults.bool(forKey: enabledKey)
        guard enabled, defaults.object(forKey: prefixKey) != nil else {
            context.completeRequest()
            return
        }

        let prefix = Int64(defaults.integer(forKey: prefixKey))
        let start = prefix * Self.blockCount
        let end = start + Self.blockCount

        for number in start..<end {
            context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }

        context.completeRequest()
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: any Error) {}
}
