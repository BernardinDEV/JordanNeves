import Foundation
import LocalAuthentication

/// Thin wrapper over LocalAuthentication for Face ID / Touch ID gating.
enum BiometricAuthenticator {

    /// True when the device has biometrics enrolled and available right now.
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Human-readable name of the device's biometry ("Face ID", "Touch ID", …).
    /// `canEvaluatePolicy` must be queried first to populate `biometryType`.
    static var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return String(localized: "biometric.generic")
        }
    }

    /// Prompts biometric evaluation. Returns true on success, false on failure or cancel.
    /// Each call uses a fresh context so a prior success can't be reused silently.
    static func evaluate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
