//
//  ClipboardServiceTests.swift
//  AnyGPTTests
//
//  Created on 2025
//

import XCTest
import Cocoa
@testable import AnyGPT

class ClipboardServiceTests: XCTestCase {

    var originalContent: String?

    override func setUp() {
        super.setUp()
        // Save original clipboard content
        originalContent = ClipboardService.shared.readText()
    }

    override func tearDown() {
        // Restore original clipboard content
        if let original = originalContent {
            ClipboardService.shared.writeText(original)
        } else {
            ClipboardService.shared.clear()
        }
        super.tearDown()
    }

    func testWriteAndReadText() {
        // Given
        let testText = "Hello, AnyGPT!"

        // When
        ClipboardService.shared.writeText(testText)
        let readText = ClipboardService.shared.readText()

        // Then
        XCTAssertEqual(readText, testText, "Read text should match written text")
    }

    func testClearClipboard() {
        // Given
        ClipboardService.shared.writeText("Some content")

        // When
        ClipboardService.shared.clear()
        let content = ClipboardService.shared.readText()

        // Then
        XCTAssertNil(content, "Clipboard should be empty after clearing")
    }

    func testGetTextLength() {
        // Given
        let testText = "Test string with 28 characters"
        ClipboardService.shared.writeText(testText)

        // When
        let length = ClipboardService.shared.getTextLength()

        // Then
        XCTAssertEqual(length, 30, "Length should match text character count")
    }

    func testHasText() {
        // Initially clear
        ClipboardService.shared.clear()
        XCTAssertFalse(ClipboardService.shared.hasText(), "Should not have text after clearing")

        // Write text
        ClipboardService.shared.writeText("Some text")
        XCTAssertTrue(ClipboardService.shared.hasText(), "Should have text after writing")
    }

    func testSaveAndRestoreState() {
        // Given
        let originalText = "Original content"
        ClipboardService.shared.writeText(originalText)

        // When
        let savedState = ClipboardService.shared.saveState()
        ClipboardService.shared.writeText("Modified content")
        ClipboardService.shared.restoreState(savedState)

        // Then
        let restoredText = ClipboardService.shared.readText()
        XCTAssertEqual(restoredText, originalText, "Restored text should match original")
    }

    func testProcessLargeText() {
        // Given
        let longText = String(repeating: "a", count: 10000)
        let maxLength = 5000

        // When
        let (processedText, wasTruncated) = ClipboardService.shared.processLargeText(longText, maxLength: maxLength)

        // Then
        XCTAssertTrue(wasTruncated, "Text should be marked as truncated")
        XCTAssertEqual(processedText.count, maxLength, "Processed text should be truncated to max length")
    }

    func testProcessSmallText() {
        // Given
        let shortText = "Short text"
        let maxLength = 100

        // When
        let (processedText, wasTruncated) = ClipboardService.shared.processLargeText(shortText, maxLength: maxLength)

        // Then
        XCTAssertFalse(wasTruncated, "Text should not be marked as truncated")
        XCTAssertEqual(processedText, shortText, "Processed text should match original")
    }

    func testEmptyClipboardHandling() {
        // Given
        ClipboardService.shared.clear()

        // When
        let text = ClipboardService.shared.readText()
        let length = ClipboardService.shared.getTextLength()
        let hasText = ClipboardService.shared.hasText()

        // Then
        XCTAssertNil(text, "Should return nil for empty clipboard")
        XCTAssertNil(length, "Should return nil length for empty clipboard")
        XCTAssertFalse(hasText, "Should return false for empty clipboard")
    }

    func testSpecialCharacters() {
        // Given
        let specialText = "Special chars: 😀 \n\t\"'<>&"

        // When
        ClipboardService.shared.writeText(specialText)
        let readText = ClipboardService.shared.readText()

        // Then
        XCTAssertEqual(readText, specialText, "Should handle special characters correctly")
    }

    func testUnicodeText() {
        // Given
        let unicodeText = "Unicode: 中文 日本語 한글 العربية עברית"

        // When
        ClipboardService.shared.writeText(unicodeText)
        let readText = ClipboardService.shared.readText()

        // Then
        XCTAssertEqual(readText, unicodeText, "Should handle Unicode text correctly")
    }

    func testMultilineText() {
        // Given
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """

        // When
        ClipboardService.shared.writeText(multilineText)
        let readText = ClipboardService.shared.readText()

        // Then
        XCTAssertEqual(readText, multilineText, "Should handle multiline text correctly")
    }

    func testSanitizedContent() {
        // Test short content
        ClipboardService.shared.writeText("Short")
        let shortSanitized = ClipboardService.shared.sanitizedContent()
        XCTAssertEqual(shortSanitized, "Short", "Short text should not be sanitized")

        // Test long content
        let longText = String(repeating: "a", count: 100)
        ClipboardService.shared.writeText(longText)
        let longSanitized = ClipboardService.shared.sanitizedContent()
        XCTAssertTrue(longSanitized.contains("..."), "Long text should be sanitized with ellipsis")
        XCTAssertTrue(longSanitized.contains("100 chars total"), "Should show total character count")

        // Test empty content
        ClipboardService.shared.clear()
        let emptySanitized = ClipboardService.shared.sanitizedContent()
        XCTAssertEqual(emptySanitized, "<empty>", "Empty clipboard should show <empty>")
    }

    func testMonitoringChanges() {
        // Given
        let expectation = self.expectation(description: "Clipboard change detected")
        var detectedChange = false

        // When
        let timer = ClipboardService.shared.startMonitoring { newText in
            if newText == "Changed text" {
                detectedChange = true
                expectation.fulfill()
            }
        }

        // Trigger a change
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ClipboardService.shared.writeText("Changed text")
        }

        // Then
        waitForExpectations(timeout: 3) { _ in
            timer.invalidate()
            XCTAssertTrue(detectedChange, "Should detect clipboard change")
        }
    }
}