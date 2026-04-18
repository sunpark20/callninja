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
                    Text("차단할 번호를 입력하세요")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.displayPattern ?? "")
                            .font(.body.monospaced())

                        if let error {
                            errorText(error)
                        } else if isReloading {
                            Text("등록 중...")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if slot.isEnabled {
                            Text("100만개 차단 중")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("차단 중지됨")
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
            Text("설정에서 켜주세요")
                .font(.caption)
                .foregroundStyle(.yellow)
        case .appGroupFailure:
            Text("앱을 재설치해 주세요")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
