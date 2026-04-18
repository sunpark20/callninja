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
                    Text("스팸 전화에서 본 번호를\n그대로 입력하세요")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("\(country.flag) \(country.name) (\(country.dialCode))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                TextField("전화번호 입력", text: $phoneNumber)
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
                    Text("확인")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("번호 입력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
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

                Text("패턴 모두 차단 (\(result.count.formatted())개)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

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
