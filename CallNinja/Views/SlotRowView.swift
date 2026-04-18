import SwiftUI

struct SlotRowView: View {

    let slot: BlockSlot
    let error: SlotError?
    let isReloading: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                statusIcon
                    .frame(width: 28)

                if slot.isEmpty {
                    Text("slot.empty")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.displayPattern ?? "")
                            .font(.body.monospaced())

                        if let error {
                            errorText(error)
                        } else if isReloading {
                            Text("slot.loading")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if slot.isEnabled {
                            Text("slot.blocking")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("slot.disabled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if !slot.isEmpty {
                    Toggle("", isOn: Binding(
                        get: { slot.isEnabled },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                    .disabled(isReloading)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if isReloading {
            ProgressView()
                .scaleEffect(0.8)
        } else if let error {
            switch error {
            case .extensionDisabled:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            case .appGroupFailure:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .reloadFailed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        } else if slot.isEmpty {
            Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
        } else if slot.isEnabled {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
        } else {
            Image(systemName: "shield.slash")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func errorText(_ error: SlotError) -> some View {
        switch error {
        case .reloadFailed(_, let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
        case .extensionDisabled:
            Text("slot.enableInSettings")
                .font(.caption)
                .foregroundStyle(.yellow)
        case .appGroupFailure:
            Text("slot.reinstallApp")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
