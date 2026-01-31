//
//  KeychainService.swift
//  AnyGPT
//
//  Created on 2025
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()

    private let service = "dev.anygpt.AnyGPT"
    private let account = "openai-api-key"

    private init() {}

    func storeAPIKey(_ apiKey: String) throws {
        // Delete any existing key first
        try? deleteAPIKey()

        let data = apiKey.data(using: .utf8)!

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }

        Logger.shared.log("API key stored in keychain", level: .info)
    }

    func retrieveAPIKey() throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            if let data = result as? Data,
               let apiKey = String(data: data, encoding: .utf8) {
                return apiKey
            }
        }

        throw KeychainError.unhandledError(status: status)
    }

    func updateAPIKey(_ apiKey: String) throws {
        let data = apiKey.data(using: .utf8)!

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // If not found, store it instead
            try storeAPIKey(apiKey)
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        } else {
            Logger.shared.log("API key updated in keychain", level: .info)
        }
    }

    func deleteAPIKey() throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }

        Logger.shared.log("API key deleted from keychain", level: .info)
    }

    func hasAPIKey() -> Bool {
        do {
            _ = try retrieveAPIKey()
            return true
        } catch {
            return false
        }
    }
}

enum KeychainError: LocalizedError {
    case noKey
    case duplicateItem
    case invalidItemFormat
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .noKey:
            return "No API key found in keychain"
        case .duplicateItem:
            return "API key already exists in keychain"
        case .invalidItemFormat:
            return "Invalid API key format"
        case .unhandledError(let status):
            if let errorMessage = SecCopyErrorMessageString(status, nil) as String? {
                return "Keychain error: \(errorMessage)"
            }
            return "Unknown keychain error: \(status)"
        }
    }

    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .noKey
        case errSecDuplicateItem:
            self = .duplicateItem
        case errSecInvalidItemRef:
            self = .invalidItemFormat
        default:
            self = .unhandledError(status: status)
        }
    }
}