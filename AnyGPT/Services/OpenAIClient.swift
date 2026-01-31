//
//  OpenAIClient.swift
//  AnyGPT
//
//  Created on 2025
//

import Foundation

// MARK: - Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let max_tokens: Int?

    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenAIResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let usage: Usage?
    let error: ErrorResponse?

    struct Choice: Codable {
        let index: Int
        let message: Message
        let finish_reason: String?

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }

    struct ErrorResponse: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

// MARK: - Errors
enum OpenAIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case apiError(String)
    case networkError(String)
    case rateLimited
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - OpenAI Client
class OpenAIClient {
    static let shared = OpenAIClient()

    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var session: URLSession
    private var currentTask: URLSessionDataTask?

    private let maxRetries = 2
    private let baseRetryDelay: TimeInterval = 0.5

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(UserDefaults.standard.integer(forKey: "timeout") > 0 ? UserDefaults.standard.integer(forKey: "timeout") : 20)
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func generate(
        text: String,
        apiKey: String,
        model: String = "gpt-4o-mini",
        systemPrompt: String = "You are a helpful assistant."
    ) async throws -> String {
        // Check text length
        let maxLength = UserDefaults.standard.integer(forKey: "maxInputLength") > 0 ? UserDefaults.standard.integer(forKey: "maxInputLength") : 4000
        let (processedText, wasTruncated) = ClipboardService.shared.processLargeText(text, maxLength: maxLength)

        if wasTruncated {
            Logger.shared.log("Input text was truncated to \(maxLength) characters", level: .warning)
        }

        // Prepare request
        let request = try createRequest(
            text: processedText,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt
        )

        // Execute with retry logic
        var lastError: Error?
        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                Logger.shared.log("Retrying after \(delay) seconds (attempt \(attempt + 1)/\(maxRetries + 1))", level: .info)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            do {
                return try await executeRequest(request)
            } catch OpenAIError.rateLimited {
                lastError = OpenAIError.rateLimited
                continue
            } catch {
                lastError = error
                if shouldRetry(error: error) {
                    continue
                } else {
                    throw error
                }
            }
        }

        throw lastError ?? OpenAIError.networkError("Unknown error after retries")
    }

    private func createRequest(
        text: String,
        apiKey: String,
        model: String,
        systemPrompt: String
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let temperature = UserDefaults.standard.double(forKey: "temperature") > 0 ? UserDefaults.standard.double(forKey: "temperature") : 0.7
        let maxTokens = UserDefaults.standard.integer(forKey: "maxTokens") > 0 ? UserDefaults.standard.integer(forKey: "maxTokens") : 500

        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIRequest.Message(role: "system", content: systemPrompt),
                OpenAIRequest.Message(role: "user", content: text)
            ],
            temperature: temperature,
            max_tokens: maxTokens
        )

        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }

    private func executeRequest(_ request: URLRequest) async throws -> String {
        Logger.shared.log("Sending request to OpenAI API", level: .debug)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError("Invalid response type")
        }

        Logger.shared.log("Received response with status code: \(httpResponse.statusCode)", level: .debug)

        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            return try parseSuccessResponse(data)
        case 429:
            throw OpenAIError.rateLimited
        case 400...499:
            let errorMessage = try parseErrorResponse(data)
            throw OpenAIError.apiError(errorMessage)
        case 500...599:
            throw OpenAIError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw OpenAIError.networkError("Unexpected status code: \(httpResponse.statusCode)")
        }
    }

    private func parseSuccessResponse(_ data: Data) throws -> String {
        do {
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            if let error = response.error {
                throw OpenAIError.apiError(error.message)
            }

            guard let content = response.choices.first?.message.content else {
                // If we can't parse, return raw JSON so user gets something
                if let jsonString = String(data: data, encoding: .utf8) {
                    Logger.shared.log("Could not extract content, returning raw JSON", level: .warning)
                    return jsonString
                }
                throw OpenAIError.noData
            }

            if let usage = response.usage {
                Logger.shared.log("Token usage - Prompt: \(usage.prompt_tokens), Completion: \(usage.completion_tokens), Total: \(usage.total_tokens)", level: .info)
            }

            return content

        } catch let decodingError as DecodingError {
            // Return raw response if we can't decode
            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.shared.log("Decoding error, returning raw response: \(decodingError)", level: .warning)
                return jsonString
            }
            throw OpenAIError.decodingError(decodingError.localizedDescription)
        }
    }

    private func parseErrorResponse(_ data: Data) throws -> String {
        if let response = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
           let error = response.error {
            return error.message
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return "Unknown error"
    }

    private func shouldRetry(error: Error) -> Bool {
        switch error {
        case let openAIError as OpenAIError:
            switch openAIError {
            case .rateLimited, .timeout, .networkError:
                return true
            default:
                return false
            }
        case let urlError as URLError:
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        // Make a minimal API call to validate the key
        let testRequest = try createRequest(
            text: "Hi",
            apiKey: apiKey,
            model: "gpt-3.5-turbo",
            systemPrompt: "You are a test."
        )

        do {
            _ = try await executeRequest(testRequest)
            return true
        } catch {
            Logger.shared.log("API key validation failed: \(error)", level: .error)
            throw error
        }
    }

    func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
    }
}