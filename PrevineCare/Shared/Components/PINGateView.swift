import SwiftUI

struct PINGateView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let validate: (String) -> Bool

    @State private var pin = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.title.bold())

                SecureField("PIN", text: $pin)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 280)

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button("Continue") {
                    if validate(pin) {
                        dismiss()
                    } else {
                        error = "Incorrect PIN."
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
        }
        .presentationDetents([.medium])
    }
}
