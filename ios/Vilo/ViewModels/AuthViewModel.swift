import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private let apiService = APIService.shared
    private let storage = Storage.shared

    init() {
        // Check for existing token
        if let token = storage.getToken() {
            validateToken(token)
        }
    }

    /// Send OTP to phone number
    func sendOTP(phone: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await apiService.sendOTP(phone: phone)
            return true
        } catch APIError.server(let message) {
            errorMessage = message
            return false
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
            return false
        }
    }

    /// Verify OTP and login
    func verifyOTP(phone: String, code: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await apiService.verifyOTP(phone: phone, code: code)

            // Save token and user
            storage.saveToken(response.token)
            storage.saveUser(response.user)

            currentUser = response.user
            isAuthenticated = true

            // Connect WebSocket
            WebSocketService.shared.connect(token: response.token)

            // Upload public keys if new user
            if response.user.isNewUser {
                await uploadKeys()
            }
        } catch APIError.unauthorized {
            errorMessage = "Invalid or expired OTP"
        } catch APIError.server(let message) {
            errorMessage = message
        } catch {
            errorMessage = "Verification failed. Please try again."
        }
    }

    /// Validate existing token
    private func validateToken(_ token: String) {
        Task {
            do {
                let user = try await apiService.getMe()
                currentUser = user
                isAuthenticated = true
                WebSocketService.shared.connect(token: token)
            } catch {
                // Token invalid, clear storage
                logout()
            }
        }
    }

    /// Upload E2EE public keys
    private func uploadKeys() async {
        do {
            let keys = try CryptoService.shared.generateKeys()
            try await apiService.uploadKeys(keys)
        } catch {
            print("Failed to upload keys: \(error)")
        }
    }

    /// Logout user
    func logout() {
        storage.clearAll()
        currentUser = nil
        isAuthenticated = false
        WebSocketService.shared.disconnect()
    }

    /// Update user profile
    func updateProfile(name: String?, avatar: String?) async {
        isLoading = true

        defer { isLoading = false }

        do {
            let user = try await apiService.updateProfile(name: name, avatar: avatar)
            currentUser = user
            storage.saveUser(user)
        } catch {
            errorMessage = "Failed to update profile"
        }
    }
}
