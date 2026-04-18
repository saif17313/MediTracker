//
//  AuthGateView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// Entry point for authentication when no user is signed in.
struct AuthGateView: View {
    @Environment(UserSessionStore.self) private var session

    @State private var mode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if !session.firebaseConfigurationState.isConfigured {
                        firebaseSetupCard
                    } else {
                        authForm
                    }
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: mode) { _, _ in
                session.clearMessages()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "cross.case.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("MediReminder")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to keep medicines, reminders, and history tied to your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var firebaseSetupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Firebase Setup Needed", systemImage: "bolt.shield")
                .font(.headline)

            Text(session.firebaseConfigurationState.userFacingMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Steps")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("1. Create a Firebase project.")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("2. Add an iOS app with this bundle ID.")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("3. Enable Email/Password in Firebase Authentication.")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("4. Download GoogleService-Info.plist and place it in MediReminder/Resources.")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
    }

    private var authForm: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                ForEach(AuthMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(mode == .signIn ? .password : .newPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if mode == .signUp {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if let infoMessage = session.infoMessage {
                Text(infoMessage)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage = session.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task {
                    if mode == .signIn {
                        await session.signIn(email: trimmedEmail, password: password)
                    } else {
                        await session.signUp(email: trimmedEmail, password: password)
                    }
                }
            } label: {
                HStack {
                    if session.isWorking {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(mode.primaryButtonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isFormValid || session.isWorking)

            if mode == .signIn {
                Button("Forgot password?") {
                    Task {
                        await session.sendPasswordReset(to: trimmedEmail)
                    }
                }
                .disabled(trimmedEmail.isEmpty || session.isWorking)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFormValid: Bool {
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            return false
        }

        if mode == .signUp {
            return password.count >= 6 && password == confirmPassword
        }

        return true
    }
}

private enum AuthMode: String, CaseIterable, Identifiable {
    case signIn
    case signUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn:
            return "Sign In"
        case .signUp:
            return "Create Account"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .signIn:
            return "Sign In"
        case .signUp:
            return "Create Account"
        }
    }
}

#Preview {
    AuthGateView()
        .environment(
            UserSessionStore(
                previewUser: nil,
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
