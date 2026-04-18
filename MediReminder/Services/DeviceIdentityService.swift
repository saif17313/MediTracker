//
//  DeviceIdentityService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import UIKit

/// Stable representation of the current app installation on this device.
struct RegisteredDevice: Sendable {
    let installationId: String
    let name: String
    let platform: String
    let systemVersion: String
}

/// Generates and stores a stable installation id for device-scoped reminder behavior.
final class DeviceIdentityService {
    static let shared = DeviceIdentityService()

    private let defaults = UserDefaults.standard
    private let installationKey = "medireminder.installation-id"

    private init() {}

    var currentDevice: RegisteredDevice {
        RegisteredDevice(
            installationId: installationId,
            name: UIDevice.current.name,
            platform: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion
        )
    }

    private var installationId: String {
        if let existing = defaults.string(forKey: installationKey), !existing.isEmpty {
            return existing
        }

        let newId = UUID().uuidString
        defaults.set(newId, forKey: installationKey)
        return newId
    }
}
