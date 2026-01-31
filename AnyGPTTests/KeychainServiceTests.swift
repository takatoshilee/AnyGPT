//
//  KeychainServiceTests.swift
//  AnyGPTTests
//
//  Created on 2025
//

import XCTest
@testable import AnyGPT

class KeychainServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear any existing key before each test
        try? KeychainService.shared.deleteAPIKey()
    }

    override func tearDown() {
        // Clean up after each test
        try? KeychainService.shared.deleteAPIKey()
        super.tearDown()
    }

    func testStoreAndRetrieveAPIKey() throws {
        // Given
        let testKey = "sk-test_api_key_123456789"

        // When
        try KeychainService.shared.storeAPIKey(testKey)
        let retrievedKey = try KeychainService.shared.retrieveAPIKey()

        // Then
        XCTAssertEqual(retrievedKey, testKey, "Retrieved key should match stored key")
    }

    func testUpdateAPIKey() throws {
        // Given
        let originalKey = "sk-original_key"
        let updatedKey = "sk-updated_key"

        // When
        try KeychainService.shared.storeAPIKey(originalKey)
        try KeychainService.shared.updateAPIKey(updatedKey)
        let retrievedKey = try KeychainService.shared.retrieveAPIKey()

        // Then
        XCTAssertEqual(retrievedKey, updatedKey, "Retrieved key should match updated key")
        XCTAssertNotEqual(retrievedKey, originalKey, "Retrieved key should not match original key")
    }

    func testDeleteAPIKey() throws {
        // Given
        let testKey = "sk-key_to_delete"
        try KeychainService.shared.storeAPIKey(testKey)

        // When
        try KeychainService.shared.deleteAPIKey()

        // Then
        XCTAssertThrowsError(try KeychainService.shared.retrieveAPIKey()) { error in
            XCTAssertTrue(error is KeychainError, "Should throw KeychainError")
            if let keychainError = error as? KeychainError {
                XCTAssertEqual(keychainError.localizedDescription, KeychainError.noKey.localizedDescription)
            }
        }
    }

    func testHasAPIKey() throws {
        // Initially no key
        XCTAssertFalse(KeychainService.shared.hasAPIKey(), "Should not have key initially")

        // Store a key
        try KeychainService.shared.storeAPIKey("sk-test_key")
        XCTAssertTrue(KeychainService.shared.hasAPIKey(), "Should have key after storing")

        // Delete the key
        try KeychainService.shared.deleteAPIKey()
        XCTAssertFalse(KeychainService.shared.hasAPIKey(), "Should not have key after deletion")
    }

    func testRetrieveNonExistentKey() {
        // When trying to retrieve a non-existent key
        XCTAssertThrowsError(try KeychainService.shared.retrieveAPIKey()) { error in
            // Then
            XCTAssertTrue(error is KeychainError, "Should throw KeychainError")
            if let keychainError = error as? KeychainError {
                XCTAssertEqual(keychainError.localizedDescription, KeychainError.noKey.localizedDescription)
            }
        }
    }

    func testStoreDuplicateKey() throws {
        // Given
        let testKey = "sk-duplicate_test"

        // When
        try KeychainService.shared.storeAPIKey(testKey)

        // Storing again should replace without error
        XCTAssertNoThrow(try KeychainService.shared.storeAPIKey(testKey))
    }

    func testKeyPersistence() throws {
        // Given
        let testKey = "sk-persistent_key"

        // When
        try KeychainService.shared.storeAPIKey(testKey)

        // Create a new instance to simulate app restart
        let newService = KeychainService.shared
        let retrievedKey = try newService.retrieveAPIKey()

        // Then
        XCTAssertEqual(retrievedKey, testKey, "Key should persist across instances")
    }

    func testSpecialCharactersInKey() throws {
        // Given
        let testKey = "sk-test!@#$%^&*()_+{}[]|\\:\";<>,.?/~`"

        // When
        try KeychainService.shared.storeAPIKey(testKey)
        let retrievedKey = try KeychainService.shared.retrieveAPIKey()

        // Then
        XCTAssertEqual(retrievedKey, testKey, "Should handle special characters correctly")
    }

    func testEmptyKey() {
        // Given
        let emptyKey = ""

        // When/Then
        XCTAssertNoThrow(try KeychainService.shared.storeAPIKey(emptyKey))
        XCTAssertEqual(try? KeychainService.shared.retrieveAPIKey(), emptyKey)
    }

    func testLongKey() throws {
        // Given
        let longKey = String(repeating: "a", count: 10000)

        // When
        try KeychainService.shared.storeAPIKey(longKey)
        let retrievedKey = try KeychainService.shared.retrieveAPIKey()

        // Then
        XCTAssertEqual(retrievedKey, longKey, "Should handle long keys correctly")
    }
}