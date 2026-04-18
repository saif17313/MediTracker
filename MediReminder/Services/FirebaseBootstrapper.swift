//
//  FirebaseBootstrapper.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import FirebaseCore

/// Tracks whether Firebase is available for the current app build.
enum FirebaseConfigurationState: Equatable {
    case configured
    case missingConfigurationFile
    case invalidConfigurationFile

    var isConfigured: Bool {
        self == .configured
    }

    var userFacingMessage: String {
        switch self {
        case .configured:
            return "Firebase is configured."
        case .missingConfigurationFile:
            return "Add your Firebase GoogleService-Info.plist file to MediReminder/Resources before signing in."
        case .invalidConfigurationFile:
            return "The Firebase configuration file could not be loaded. Download a fresh GoogleService-Info.plist from Firebase Console."
        }
    }
}

/// Configures Firebase when the local configuration file is available.
enum FirebaseBootstrapper {
    static func configureIfNeeded(bundle: Bundle = .main) -> FirebaseConfigurationState {
        if FirebaseApp.app() != nil {
            return .configured
        }

        guard let configPath = bundle.path(forResource: "GoogleService-Info", ofType: "plist") else {
            return .missingConfigurationFile
        }

        guard let options = FirebaseOptions(contentsOfFile: configPath) else {
            return .invalidConfigurationFile
        }

        FirebaseApp.configure(options: options)
        return .configured
    }
}
