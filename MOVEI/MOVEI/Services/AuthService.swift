//
//  AuthService.swift
//  MOVEI
//

import SwiftUI
import Combine

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var currentUser: Profile?
    @Published public var currentUserEmail: String = ""
    @Published public var isAuthenticated: Bool = false
    @Published public var currentRole: UserRole = .customer
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private init() {
        // Clear previous legacy session to start brand new
        UserDefaults.standard.removeObject(forKey: "movei_cached_profile")
        loadSavedUser()
    }

    private func loadSavedUser() {
        if let data = UserDefaults.standard.data(forKey: "movei_cached_profile_v2"),
           let profile = try? JSONDecoder().decode(Profile.self, from: data) {
            self.currentUser = profile
            self.currentUserEmail = UserDefaults.standard.string(forKey: "movei_cached_email") ?? ""
            self.currentRole = profile.role
            self.isAuthenticated = true
        } else {
            // Brand new system starts unauthenticated on Login screen
            self.currentUser = nil
            self.currentUserEmail = ""
            self.isAuthenticated = false
            self.currentRole = .customer
        }
    }

    public func signIn(email: String, password: String, role: UserRole? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(300))

        let determinedRole: UserRole
        let name: String
        if let role = role {
            determinedRole = role
            name = email.components(separatedBy: "@").first?.capitalized ?? role.title
        } else if email.lowercased().contains("admin") {
            determinedRole = .admin
            name = "Cinema Admin"
        } else if email.lowercased().contains("scanner") || email.lowercased().contains("staff") {
            determinedRole = .scanner
            name = "Staff Scanner"
        } else {
            determinedRole = .customer
            name = email.components(separatedBy: "@").first?.capitalized ?? "Customer"
        }

        let profile = Profile(id: UUID(), fullName: name, role: determinedRole)
        self.currentUserEmail = email
        UserDefaults.standard.set(email, forKey: "movei_cached_email")
        saveProfile(profile)
        await syncUserToBackend(profile: profile, email: email)
        return true
    }

    public func register(fullName: String, email: String, password: String, role: UserRole = .customer) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(300))
        let profile = Profile(id: UUID(), fullName: fullName, role: role)
        self.currentUserEmail = email
        UserDefaults.standard.set(email, forKey: "movei_cached_email")
        saveProfile(profile)
        await syncUserToBackend(profile: profile, email: email)
        return true
    }

    public func updateRole(to role: UserRole) {
        guard var profile = currentUser else { return }
        profile.role = role
        saveProfile(profile)
        Task {
            await syncUserToBackend(profile: profile, email: currentUserEmail)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    public func signOut() {
        currentUser = nil
        currentUserEmail = ""
        isAuthenticated = false
        currentRole = .customer
        UserDefaults.standard.removeObject(forKey: "movei_cached_profile_v2")
        UserDefaults.standard.removeObject(forKey: "movei_cached_email")
        SupabaseManager.shared.clearSession()
    }

    private func saveProfile(_ profile: Profile) {
        self.currentUser = profile
        self.currentRole = profile.role
        self.isAuthenticated = true
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "movei_cached_profile_v2")
        }
    }

    private func syncUserToBackend(profile: Profile, email: String) async {
        let baseURL = MovieService.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/api/users") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 4.0

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let payload: [String: Any] = [
            "id": profile.id.uuidString,
            "name": profile.fullName,
            "email": cleanEmail.isEmpty ? "\(profile.role.rawValue)@movei.app" : cleanEmail,
            "role": profile.role.rawValue,
            "device": "iOS App"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("[AuthService] Synced user \(cleanEmail) to Web Admin")
            }
        } catch {
            print("[AuthService] Note: User registered locally; backend sync skipped (\(error.localizedDescription))")
        }
    }
}
