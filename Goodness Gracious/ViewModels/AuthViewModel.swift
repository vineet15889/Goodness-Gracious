import Foundation
import FirebaseAuth

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Phone auth state
    @Published var phoneNumber: String = ""
    @Published var smsCode: String = ""
    @Published var verificationId: String?
    @Published var codeSent: Bool = false
    
    // Auth state listener
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Set up auth state listener to maintain session
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        // Remove listener when view model is deallocated
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
    }

    func requestCode() {
        errorMessage = nil
        var trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Special handling for test number
        if trimmed == "9335922265" {
            // This is our test number, ensure proper formatting
            trimmed = "+91" + trimmed
            phoneNumber = trimmed
            
            // For test number, we can simulate code sent
            isLoading = true
            Task { @MainActor in
                // Short delay to simulate network request
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                verificationId = "test-verification-id"
                codeSent = true
                isLoading = false
            }
            return
        }
        
        // Normal phone number handling
        if !trimmed.hasPrefix("+") {
            // Simple normalization: assume India if no country code and 10 digits
            let digits = trimmed.filter { $0.isNumber }
            if digits.count == 10 { trimmed = "+91" + digits }
        }
        phoneNumber = trimmed
        
        guard !trimmed.isEmpty else {
            errorMessage = "Enter phone number"
            return
        }
        
        isLoading = true
        Task { @MainActor in
            do {
                let id = try await AuthService.shared.sendVerificationCode(to: trimmed)
                verificationId = id
                codeSent = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func confirmCode() {
        errorMessage = nil
        guard let verificationId, !smsCode.isEmpty else {
            errorMessage = "Enter the code sent to your phone"
            return
        }
        
        // Special handling for test verification
        if verificationId == "test-verification-id" && smsCode == "000000" {
            isLoading = true
            Task { @MainActor in
                // Short delay to simulate network request
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isAuthenticated = true
                isLoading = false
            }
            return
        }
        
        isLoading = true
        Task { @MainActor in
            do {
                try await AuthService.shared.verifyCode(verificationId: verificationId, code: smsCode)
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            // ignore for demo
        }
        isAuthenticated = false
        codeSent = false
        verificationId = nil
        smsCode = ""
    }
}


