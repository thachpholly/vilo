import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var showOTPField = false
    @FocusState private var focusedField: Field?

    enum Field {
        case phone, otp
    }

    var body: some View {
        ZStack {
            Color.viloBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Text("V")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.viloSecondary)
                        .padding(24)
                        .background(
                            Circle()
                                .fill(Color.viloPrimary)
                        )

                    Text("VILO")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.viloTextPrimary)

                    Text("Private chat, no trace")
                        .font(.subheadline)
                        .foregroundColor(.viloTextSecondary)
                }

                Spacer()

                // Input Fields
                VStack(spacing: 16) {
                    // Phone Number Input
                    HStack(spacing: 12) {
                        Text("🇻🇳 +84")
                            .foregroundColor(.viloTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .background(Color.viloSurface)
                            .cornerRadius(12)

                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .foregroundColor(.viloTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.viloSurface)
                            .cornerRadius(12)
                            .focused($focusedField, equals: .phone)
                            .disabled(showOTPField)
                    }

                    // OTP Input (shown after sending OTP)
                    if showOTPField {
                        TextField("Enter 6-digit OTP", text: $otpCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.viloTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.viloSurface)
                            .cornerRadius(12)
                            .focused($focusedField, equals: .otp)
                            .onChange(of: otpCode) { newValue in
                                // Auto-verify when 6 digits entered
                                if newValue.count == 6 {
                                    verifyOTP()
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)

                // Action Button
                Button(action: {
                    if showOTPField {
                        verifyOTP()
                    } else {
                        sendOTP()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(showOTPField ? "Verify" : "Send OTP")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isButtonEnabled ? Color.viloPrimary : Color.viloBorder)
                    .cornerRadius(12)
                }
                .disabled(!isButtonEnabled || authViewModel.isLoading)
                .padding(.horizontal, 24)

                // Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.viloError)
                        .padding(.horizontal, 24)
                }

                // Change number link
                if showOTPField {
                    Button("Change phone number") {
                        withAnimation {
                            showOTPField = false
                            otpCode = ""
                            authViewModel.errorMessage = nil
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.viloTextSecondary)
                }

                Spacer()
            }
        }
        .onAppear {
            focusedField = .phone
        }
    }

    private var isButtonEnabled: Bool {
        if showOTPField {
            return otpCode.count == 6
        } else {
            return phoneNumber.count >= 9
        }
    }

    private var formattedPhone: String {
        return "+84" + phoneNumber.filter { $0.isNumber }
    }

    private func sendOTP() {
        Task {
            let success = await authViewModel.sendOTP(phone: formattedPhone)
            if success {
                withAnimation {
                    showOTPField = true
                    focusedField = .otp
                }
            }
        }
    }

    private func verifyOTP() {
        Task {
            await authViewModel.verifyOTP(phone: formattedPhone, code: otpCode)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
