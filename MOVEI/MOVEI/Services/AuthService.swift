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

    private struct BackendUserRecord: Codable {
        let id: String
        let name: String
        let email: String
        let role: String
        let password: String?
        let created_by: String?
    }

    private func verifyAdminCredentials(email: String, password: String) async -> (role: UserRole, name: String)? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 1. Direct local studio disk file inspection (Simulator / Mac development)
        let diskPath = "/Users/sandew/Swifts/MOVEI/web/movei-web/data/users.json"
        if FileManager.default.fileExists(atPath: diskPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: diskPath)),
           let records = try? JSONDecoder().decode([BackendUserRecord].self, from: data) {
            if let match = records.first(where: { $0.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanEmail }) {
                // If password was set by admin, verify it matches
                if let savedPass = match.password, !savedPass.isEmpty {
                    guard savedPass == password else {
                        return nil // Password mismatch
                    }
                }
                let role = UserRole(rawValue: match.role.lowercased()) ?? .customer
                return (role, match.name)
            }
        }

        // 2. Network verification across candidate backend endpoints
        let candidateBases = [
            MovieService.shared.activeBaseURL,
            "http://192.168.1.12:3000",
            "http://Sandews-MacBook-Air.local:3000",
            "http://localhost:3000",
            "http://127.0.0.1:3000"
        ]

        for base in candidateBases {
            guard let url = URL(string: "\(base)/api/auth/login") else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 3.0

            let payload = ["email": cleanEmail, "password": password]
            guard let body = try? JSONSerialization.data(withJSONObject: payload) else { continue }
            request.httpBody = body

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userObj = json["user"] as? [String: Any],
                   let roleStr = userObj["role"] as? String {
                    let role = UserRole(rawValue: roleStr.lowercased()) ?? .customer
                    let name = (userObj["name"] as? String) ?? "Staff Member"
                    return (role, name)
                }
            } catch {
                // Try next endpoint
            }
        }

        return nil
    }

    public func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(250))

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return false
        }

        // 1. Verify against admin-created staff credentials
        if let staffInfo = await verifyAdminCredentials(email: cleanEmail, password: password) {
            let profile = Profile(id: UUID(), fullName: staffInfo.name, role: staffInfo.role)
            self.currentUserEmail = cleanEmail
            UserDefaults.standard.set(cleanEmail, forKey: "movei_cached_email")
            saveProfile(profile)
            await syncUserToBackend(profile: profile, email: cleanEmail)
            return true
        }

        // 2. If it's a known admin/staff address with wrong password, reject
        let isStaffTarget = cleanEmail == "admin@movei.app" || cleanEmail == "scanner@movei.app"
        if isStaffTarget {
            errorMessage = "Invalid password for staff account. Please verify credentials provisioned by Cinema Admin."
            return false
        }

        // 3. Normal customer sign in
        let name = cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Customer"
        let profile = Profile(id: UUID(), fullName: name, role: .customer)
        self.currentUserEmail = cleanEmail
        UserDefaults.standard.set(cleanEmail, forKey: "movei_cached_email")
        saveProfile(profile)
        await syncUserToBackend(profile: profile, email: cleanEmail)
        return true
    }

    public func register(fullName: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(250))
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // App registration strictly creates customer accounts
        let profile = Profile(id: UUID(), fullName: fullName, role: .customer)
        self.currentUserEmail = cleanEmail
        UserDefaults.standard.set(cleanEmail, forKey: "movei_cached_email")
        saveProfile(profile)
        await syncUserToBackend(profile: profile, email: cleanEmail)
        return true
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
