import SwiftUI

struct NumberInputView: View {

    let country: CountryCode
    let existingPrefixes: [Int64?]
    let currentInput: String?
    let onConfirm: (E164Result, String) -> Void

    @State private var phoneNumber: String = ""
    @Environment(\.dismiss) private var dismiss

    private var conversionResult: Result<E164Result, E164Error>? {
        let digits = phoneNumber.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return E164Converter.convert(
            input: phoneNumber,
            country: country,
            existingPrefixes: existingPrefixes
        )
    }

    private var isValid: Bool {
        if case .success = conversionResult { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("numberInput.instruction")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("\(country.flag) \(country.displayName) (\(country.dialCode))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                TextField(String(localized: "numberInput.placeholder"), text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.title2.monospaced())
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                previewSection

                Spacer()

                Button {
                    if case .success(let result) = conversionResult {
                        onConfirm(result, phoneNumber)
                    }
                } label: {
                    Text("numberInput.confirm")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(String(localized: "numberInput.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("numberInput.cancel") { dismiss() }
                }
            }
            .onAppear {
                if let currentInput {
                    phoneNumber = currentInput
                }
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        switch conversionResult {
        case .success(let result):
            VStack(spacing: 8) {
                Text(result.displayPattern)
                    .font(.title.monospaced().bold())
                    .foregroundStyle(.green)

                Text("numberInput.blockPattern \(result.count.formatted())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(duration: 0.28, bounce: 0.3), value: result.prefix)

        case .failure(let error):
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.orange)
                .padding(.horizontal)

        case nil:
            EmptyView()
        }
    }
}
