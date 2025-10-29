import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var animate = false

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(colors: [.purple.opacity(0.7), .blue.opacity(0.7), .pink.opacity(0.7)], startPoint: animate ? .topLeading : .bottomTrailing, endPoint: animate ? .bottomTrailing : .topLeading)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Goodness Gracious")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("Sign in with your phone number")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    TextField("Phone (e.g. +1 555 123 4567)", text: $auth.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if auth.codeSent {
                        SecureField("6-digit code", text: $auth.smsCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                Button(action: { auth.codeSent ? auth.confirmCode() : auth.requestCode() }) {
                    HStack(spacing: 10) {
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                                .transition(.opacity.combined(with: .scale))
                        }
                        Text(auth.isLoading ? (auth.codeSent ? "Verifying..." : "Sending...") : (auth.codeSent ? "Verify Code" : "Send Code"))
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.18))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                }
                .disabled(auth.isLoading)
                .padding(.top, 4)
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, 6)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(20)
        }
        .onAppear { animate = true }
    }
}


