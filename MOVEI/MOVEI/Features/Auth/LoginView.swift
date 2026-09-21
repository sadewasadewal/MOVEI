//
//  LoginView.swift
//  MOVEI
//

import SwiftUI

public struct LoginView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var authMode: AuthMode = .signIn
    
    // Form fields
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .customer
    @State private var localError: String?

    enum AuthMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case register = "Create Account"
        var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Branding
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text("MOVEI")
                                .font(.system(size: 40, weight: .black))
                                .foregroundStyle(AppTheme.ink)
                            Text("•")
                                .font(.system(size: 40, weight: .black))
                                .foregroundStyle(AppTheme.lime)
                        }
                        Text("CINEMA EXPERIENCE PLATFORM")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .padding(.top, 36)

                    // Mode Switcher (Sign In vs Create Account)
                    HStack(spacing: 0) {
                        ForEach(AuthMode.allCases) { mode in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    authMode = mode
                                    localError = nil
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(authMode == mode ? Color.black : AppTheme.muted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        authMode == mode ?
                                        AppTheme.lime :
                                        Color.clear
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(4)
                    .background(AppTheme.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Error Message
                    if let err = localError ?? auth.errorMessage {
                        Text(err)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    // Dynamic Form Inputs
                    VStack(spacing: 14) {
                        if authMode == .register {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppTheme.muted)
                                    .frame(width: 20)
                                TextField("Full Name", text: $fullName)
                                    .foregroundStyle(AppTheme.ink)
                                    .autocorrectionDisabled()
                            }
                            .padding(16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                            )
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(AppTheme.muted)
                                .frame(width: 20)
                            TextField("Email Address", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(AppTheme.ink)
                        }
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(AppTheme.muted)
                                .frame(width: 20)
                            SecureField(authMode == .register ? "Password (min 6 chars)" : "Password", text: $password)
                                .foregroundStyle(AppTheme.ink)
                        }
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                        )

                        // Role Picker when creating account
                        if authMode == .register {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACCOUNT TYPE")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.muted)
                                    .padding(.leading, 4)

                                HStack(spacing: 8) {
                                    ForEach(UserRole.allCases) { role in
                                        Button {
                                            selectedRole = role
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: role.badgeIcon)
                                                    .font(.caption2)
                                                Text(role.title)
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .foregroundStyle(selectedRole == role ? Color.black : AppTheme.ink)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedRole == role ?
                                                AppTheme.lime :
                                                AppTheme.surface
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedRole == role ?
                                                        AppTheme.lime :
                                                        AppTheme.muted.opacity(0.15),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }

                        // Submit Button
                        Button {
                            handleAuthAction()
                        } label: {
                            HStack(spacing: 8) {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text(authMode == .signIn ? "Sign In" : "Create Account & Enter")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.black)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.lime, in: Capsule())
                            .shadow(color: AppTheme.lime.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(auth.isLoading || isFormInvalid)
                        .opacity(isFormInvalid ? 0.6 : 1.0)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
            .background(AppTheme.canvas.ignoresSafeArea())
        }
    }

    private var isFormInvalid: Bool {
        if authMode == .register {
            return fullName.trimmingCharacters(in: .whitespaces).isEmpty ||
                   email.trimmingCharacters(in: .whitespaces).isEmpty ||
                   password.count < 6
        } else {
            return email.trimmingCharacters(in: .whitespaces).isEmpty ||
                   password.isEmpty
        }
    }

    private func handleAuthAction() {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            if authMode == .signIn {
                _ = await auth.signIn(email: trimmedEmail, password: password)
            } else {
                let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = await auth.register(
                    fullName: name.isEmpty ? "Customer" : name,
                    email: trimmedEmail,
                    password: password,
                    role: selectedRole
                )
            }
        }
    }
}
