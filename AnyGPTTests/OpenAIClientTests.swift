//
//  OpenAIClientTests.swift
//  AnyGPTTests
//
//  Created on 2025
//

import XCTest
@testable import AnyGPT

class OpenAIClientTests: XCTestCase {

    func testParseSuccessResponse() throws {
        // Given
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4o-mini",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello! How can I help you today?"
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 8,
                "total_tokens": 18
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertEqual(response.choices.first?.message.content, "Hello! How can I help you today?")
        XCTAssertEqual(response.usage?.total_tokens, 18)
        XCTAssertEqual(response.model, "gpt-4o-mini")
    }

    func testParseErrorResponse() throws {
        // Given
        let json = """
        {
            "error": {
                "message": "Invalid API key provided",
                "type": "invalid_request_error",
                "code": "invalid_api_key"
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.message, "Invalid API key provided")
        XCTAssertEqual(response.error?.type, "invalid_request_error")
        XCTAssertEqual(response.error?.code, "invalid_api_key")
    }

    func testParseMultipleChoices() throws {
        // Given
        let json = """
        {
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "First response"
                    }
                },
                {
                    "index": 1,
                    "message": {
                        "role": "assistant",
                        "content": "Second response"
                    }
                }
            ]
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertEqual(response.choices.count, 2)
        XCTAssertEqual(response.choices[0].message.content, "First response")
        XCTAssertEqual(response.choices[1].message.content, "Second response")
    }

    func testCreateRequestBody() throws {
        // Given
        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIRequest.Message(role: "system", content: "You are helpful."),
                OpenAIRequest.Message(role: "user", content: "Hello")
            ],
            temperature: 0.7,
            max_tokens: 100
        )

        // When
        let data = try JSONEncoder().encode(request)
        let decodedRequest = try JSONDecoder().decode(OpenAIRequest.self, from: data)

        // Then
        XCTAssertEqual(decodedRequest.model, "gpt-4o-mini")
        XCTAssertEqual(decodedRequest.messages.count, 2)
        XCTAssertEqual(decodedRequest.messages[0].role, "system")
        XCTAssertEqual(decodedRequest.messages[1].content, "Hello")
        XCTAssertEqual(decodedRequest.temperature, 0.7)
        XCTAssertEqual(decodedRequest.max_tokens, 100)
    }

    func testParseEmptyChoices() throws {
        // Given
        let json = """
        {
            "choices": []
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertTrue(response.choices.isEmpty)
        XCTAssertNil(response.choices.first?.message.content)
    }

    func testParseMissingContent() throws {
        // Given
        let json = """
        {
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": ""
                }
            }]
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertEqual(response.choices.first?.message.content, "")
    }

    func testParseTokenUsage() throws {
        // Given
        let json = """
        {
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Test"
                }
            }],
            "usage": {
                "prompt_tokens": 15,
                "completion_tokens": 20,
                "total_tokens": 35
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertNotNil(response.usage)
        XCTAssertEqual(response.usage?.prompt_tokens, 15)
        XCTAssertEqual(response.usage?.completion_tokens, 20)
        XCTAssertEqual(response.usage?.total_tokens, 35)
    }

    func testErrorLocalization() {
        // Given
        let errors: [OpenAIError] = [
            .invalidURL,
            .noData,
            .decodingError("Test decoding error"),
            .apiError("Test API error"),
            .networkError("Test network error"),
            .rateLimited,
            .timeout
        ]

        // Then
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testInvalidJSONHandling() {
        // Given
        let invalidJSON = "This is not valid JSON"
        let data = invalidJSON.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try JSONDecoder().decode(OpenAIResponse.self, from: data))
    }

    func testPartialResponseHandling() throws {
        // Given - Missing required fields
        let json = """
        {
            "id": "test",
            "object": "chat.completion"
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Then
        XCTAssertTrue(response.choices.isEmpty)
        XCTAssertNil(response.usage)
    }
}