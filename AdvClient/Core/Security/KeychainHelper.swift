import Foundation
import Security

/// Minimal wrapper over the iOS Keychain for storing small, sensitive strings
/// (the authenticated session and its cached client record).
enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "br.adv.advclient"

    // AfterFirstUnlock so writes triggered on foreground transitions
    // (session refresh → logout) can't fail while the device is locked.
    // Still ThisDeviceOnly: never synchronized to iCloud, never migrated to a new device.
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String:      data,
            kSecAttrAccessible as String: accessibility
        ]

        // Update in place — the old value is replaced atomically, never
        // deleted first, so a failed write cannot destroy the existing item.
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        guard updateStatus == errSecItemNotFound else { return false }

        var addQuery = query
        addQuery[kSecValueData as String]          = data
        addQuery[kSecAttrAccessible as String]     = accessibility
        addQuery[kSecAttrSynchronizable as String] = kCFBooleanFalse as Any
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
