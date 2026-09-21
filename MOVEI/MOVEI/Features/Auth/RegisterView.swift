//
//  RegisterView.swift
//  MOVEI
//

import SwiftUI

public struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .customer

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.ink)
                    Text("Join MOVEI for cinema tickets & collectibles")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    TextField("Full Name", text: $fullName)
                        .padding(16)
                        .background(AppTheme.surface)
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                        )

                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(16)
                        .background(AppTheme.surface)
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                        )

                    SecureField("Password (min 6 characters)", text: $password)
                        .padding(16)
                        .background(AppTheme.surface)
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.muted.opacity(0.15), lineWidth: 1)
                        )

                    HStack(spacing: 8) {
                        ForEach(UserRole.allCases) { r in
                            Button {
                                role = r
                            } label: {
                                Text(r.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(role == r ? Color.black : AppTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(role == r ? AppTheme.lime : AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.top, 4)

                    Button {
                        Task {
                            let ok = await auth.register(fullName: fullName, email: email, password: password, role: role)
                            if ok { dismiss() }
                        }
                    } label: {
                        Text("Register")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.lime, in: Capsule())
                    }
                    .disabled(fullName.isEmpty || email.isEmpty || password.count < 6)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
