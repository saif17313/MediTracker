//
//  AuthenticatedUser.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation

/// Lightweight representation of the signed-in Firebase user.
struct AuthenticatedUser: Equatable {
    let uid: String
    let email: String
}
