//
//  AuthService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import FirebaseAuth

/// Authentication state reported by Firebase Auth.
enum AuthSessionState: Equatable, Sendable {
    case loading
    case signedOut
    case signedIn(AuthenticatedUser)
}

/// Thin wrapper around Firebase Authentication.
final class AuthService {
    private lazy var auth = Auth.auth()
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    deinit {
        if let listenerHandle {
            auth.removeStateDidChangeListener(listenerHandle)
        }
    }

    func startListening(onChange: @escaping @Sendable (AuthSessionState) -> Void) {
        listenerHandle = auth.addStateDidChangeListener { _, user in
            if let user {
                onChange(.signedIn(AuthenticatedUser(uid: user.uid, email: user.email ?? "")))
            } else {
                onChange(.signedOut)
            }
        }
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            auth.signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: AuthenticatedUser(uid: user.uid, email: user.email ?? email))
            }
        }
    }

    func signUp(email: String, password: String) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: AuthenticatedUser(uid: user.uid, email: user.email ?? email))
            }
        }
    }

    func sendPasswordReset(to email: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            auth.sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func signOut() throws {
        try auth.signOut()
    }
}

enum AuthServiceError: LocalizedError {
    case missingUser

    var errorDescription: String? {
        switch self {
        case .missingUser:
            return "Firebase did not return a signed-in user."
        }
    }
}
