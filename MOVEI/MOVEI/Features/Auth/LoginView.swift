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
                VStack(spacing: 22) {
                    
                    // Top Cinematic Header with Animated Ticket Pass
                    VStack(spacing: 14) {
                        LottieAnimationView()
                            .padding(.top, 12)

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("MOVEI")
                                    .font(.system(size: 36, weight: .black))
                                    .foregroundStyle(Color.white)
                                Text("•")
                                    .font(.system(size: 36, weight: .black))
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            Text("CINEMA EXPERIENCE PLATFORM")
                                .font(.system(size: 10, weight: .black))
                                .tracking(3)
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                    }

                    // High-Contrast Monochrome Mode Switcher
                    HStack(spacing: 0) {
                        ForEach(AuthMode.allCases) { mode in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    authMode = mode
                                    localError = nil
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(authMode == mode ? Color.black : Color.white.opacity(0.85))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(
                                        authMode == mode ?
                                        Color.white :
                                        Color.clear
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(4)
                    .background(Color(white: 0.12))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Error Message
                    if let err = localError ?? auth.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(err)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                    }

                    // Form Inputs with Crystal-Clear High-Contrast Placeholders
                    VStack(spacing: 14) {
                        if authMode == .register {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(Color.white.opacity(0.85))
                                    .frame(width: 20)

                                ZStack(alignment: .leading) {
                                    if fullName.isEmpty {
                                        Text("Full Name")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.white.opacity(0.65))
                                    }
                                    TextField("", text: $fullName)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.white)
                                        .tint(Color.white)
                                        .autocorrectionDisabled()
                                }
                            }
                            .padding(16)
                            .background(Color(white: 0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color.white.opacity(0.85))
                                .frame(width: 20)

                            ZStack(alignment: .leading) {
                                if email.isEmpty {
                                    Text("Email Address")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.white.opacity(0.65))
                                }
                                TextField("", text: $email)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white)
                                    .tint(Color.white)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                        }
                        .padding(16)
                        .background(Color(white: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.white.opacity(0.85))
                                .frame(width: 20)

                            ZStack(alignment: .leading) {
                                if password.isEmpty {
                                    Text(authMode == .register ? "Password (min 6 characters)" : "Password")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.white.opacity(0.65))
                                }
                                SecureField("", text: $password)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white)
                                    .tint(Color.white)
                            }
                        }
                        .padding(16)
                        .background(Color(white: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        // Action Button with Always-Readable High-Contrast Typography
                        Button {
                            handleAuthAction()
                        } label: {
                            HStack(spacing: 8) {
                                if auth.isLoading {
                                    ProgressView()
                                        .tint(isFormInvalid ? .white : .black)
                                } else {
                                    Text(authMode == .signIn ? "Sign In" : "Create Account & Enter")
                                        .font(.headline.weight(.black))
                                        .foregroundStyle(isFormInvalid ? Color.white.opacity(0.75) : Color.black)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.black))
                                        .foregroundStyle(isFormInvalid ? Color.white.opacity(0.75) : Color.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                isFormInvalid ?
                                Color(white: 0.20) :
                                Color.white,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isFormInvalid ? Color.white.opacity(0.22) : Color.white, lineWidth: 1)
                            )
                            .shadow(color: isFormInvalid ? Color.clear : Color.white.opacity(0.25), radius: 10, y: 4)
                        }
                        .disabled(auth.isLoading || isFormInvalid)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)

                    // Clearly Legible Monochrome Staff Notice
                    VStack(spacing: 5) {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.75))
                            Text("STAFF ACCESS INFORMATION")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1.8)
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        Text("Scanner & Admin accounts are provisioned exclusively by Cinema Administration via the Web Studio.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 36)
                }
            }
            .background(Color.black.ignoresSafeArea())
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
                    password: password
                )
            }
        }
    }
}
