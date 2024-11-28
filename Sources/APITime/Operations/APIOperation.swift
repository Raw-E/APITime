import Foundation
import LoggingTime

public protocol APIOperation {
    associatedtype RequestDataModel: HTTPRequestDataModel = NoRequestData
    associatedtype ResponseDataModel: Decodable

    var apiConfigurationKey: String { get }

    var method: HTTPEndpoint.HTTPMethod { get }
    var path: String { get }

    var requestData: RequestDataModel { get }
    var requestDataEncoder: JSONEncoder { get }
    var responseDataDecoder: JSONDecoder { get }

    init(requestData: RequestDataModel)
}

extension APIOperation {
    public var requestDataEncoder: JSONEncoder { JSONEncoder() }
    public var responseDataDcoder: JSONDecoder { JSONDecoder() }
    internal var urlRequestConfigurator: URLRequestConfigurator {
        URLRequestConfigurator(encoder: requestDataEncoder)
    }
}

extension APIOperation {
    public var endpoint: HTTPEndpoint {
        get async throws {
            guard
                let apiConfiguration = await APIConfigurations.shared.getConfiguration(
                    forKey: apiConfigurationKey)
            else {
                throw APIError.configurationNotFound(key: apiConfigurationKey)
            }
            return HTTPEndpoint(method: method, baseURL: apiConfiguration.apiBaseURL, path: path)
        }
    }

    public var urlRequest: URLRequest {
        get async throws {
            let endpoint = try await self.endpoint
            var request = URLRequest(url: endpoint.url)
            request.httpMethod = method.rawValue

            try urlRequestConfigurator.configure(&request, with: requestData)

            return request
        }
    }
}

extension APIOperation {
    public func execute() async throws -> ResponseDataModel {
        PreviewLogger.log("Executing \(String(describing: Self.self))", level: .debug)

        let request = try await urlRequest
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)

        PreviewLogger.log(
            "Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")",
            level: .debug)

        return try decodeResponse(from: data)
    }

    public static func execute(_ requestData: RequestDataModel) async throws -> ResponseDataModel {
        let operation = Self(requestData: requestData)
        do {
            let response = try await operation.execute()
            return response
        } catch {
            PreviewLogger.log(
                "Failed to execute \(String(describing: Self.self)): \(error.localizedDescription)",
                level: .error)
            throw error
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(description: "Response is not an HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) {
                result, header in
                if let key = header.key as? String, let value = header.value as? String {
                    result[key] = value
                }
            }

            let diagnostics = [
                ("Error Type", "HTTP Error"),
                ("Status Code", String(statusCode)),
                ("Headers", headers.description),
            ]

            let errorMessage = diagnostics.map { "\($0.0):\n\t\($0.1)" }.joined(separator: "\n")
            PreviewLogger.log(errorMessage, level: .error)

            throw APIError.httpError(statusCode: statusCode, headers: headers)
        }
    }

    private func decodeResponse(from data: Data) throws -> ResponseDataModel {
        // Log raw data first
        if let rawString = String(data: data, encoding: .utf8) {
            PreviewLogger.log("Attempting to decode raw JSON: \(rawString)", level: .debug)
        }

        do {
            let decodedResponse = try responseDataDecoder.decode(ResponseDataModel.self, from: data)
            PreviewLogger.log("Decoded response: \(decodedResponse)", level: .debug)
            return decodedResponse
        } catch let decodingError as DecodingError {
            // Create common diagnostic info
            var diagnostics: [(String, String)] = []

            // Add error-specific information
            switch decodingError {
            case .keyNotFound(let key, let context):
                let pathString = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                diagnostics = [
                    ("Error Type", "Missing Key '\(key.stringValue)'"),
                    ("Location", pathString.isEmpty ? "Root Level" : pathString),
                    ("Description", context.debugDescription),
                    ("Underlying Error", context.underlyingError?.localizedDescription ?? "None"),
                ]
            case .valueNotFound(let type, let context):
                let pathString = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                diagnostics = [
                    ("Error Type", "Missing Value of type '\(type)'"),
                    ("Location", pathString.isEmpty ? "Root Level" : pathString),
                    ("Description", context.debugDescription),
                    ("Underlying Error", context.underlyingError?.localizedDescription ?? "None"),
                ]
            case .typeMismatch(let type, let context):
                let pathString = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                diagnostics = [
                    ("Error Type", "Type Mismatch (expected '\(type)')"),
                    ("Location", pathString.isEmpty ? "Root Level" : pathString),
                    ("Description", context.debugDescription),
                    ("Underlying Error", context.underlyingError?.localizedDescription ?? "None"),
                ]
            case .dataCorrupted(let context):
                let pathString = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                diagnostics = [
                    ("Error Type", "Data Corruption"),
                    ("Location", pathString.isEmpty ? "Root Level" : pathString),
                    ("Description", context.debugDescription),
                    ("Underlying Error", context.underlyingError?.localizedDescription ?? "None"),
                ]
            @unknown default:
                diagnostics = [
                    ("Error Type", "Unknown Decoding Error"),
                    ("Description", decodingError.localizedDescription),
                ]
            }

            // Add raw JSON to diagnostics
            if let rawString = String(data: data, encoding: .utf8) {
                diagnostics.append(
                    (
                        "Raw JSON",
                        rawString.count > 1000
                            ? "\(rawString.prefix(1000))... (truncated)" : rawString
                    ))
            }

            let errorMessage = diagnostics.map { "\($0.0):\n\t\($0.1)" }.joined(separator: "\n")
            PreviewLogger.log(errorMessage, level: .error)
            throw decodingError
        }
    }
}

extension APIOperation where RequestDataModel == NoRequestData {
    public var requestData: RequestDataModel { NoRequestData() }
}

public func executeAPIOperation<T: APIOperation>(_ operation: T) async throws -> T.ResponseDataModel {
    do {
        let response = try await operation.execute()
        return response
    } catch {
        PreviewLogger.log("Operation failed: \(error.localizedDescription)", level: .error)
        throw error
    }
}

// Add this enum somewhere in your APITime module
public enum APIError: Error, Sendable {
    case configurationNotFound(key: String)
    case invalidResponse(description: String)
    case httpError(statusCode: Int, headers: [String: String])
}

// Add LocalizedError conformance
extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configurationNotFound(let key):
            return "API configuration not found for key: \(key)"
        case .invalidResponse(let description):
            return "Invalid response: \(description)"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        }
    }
}

// Potential way to bypass needing default init

// /// A base struct that implements APIOperation protocol with default initialization
// open class BaseAPIOperation<Request: HTTPRequestDataModel, Response: Decodable>: APIOperation {
//     public var responseDataDecoder: JSONDecoder = JSONDecoder()

//     public typealias RequestDataModel = Request
//     public typealias ResponseDataModel = Response

//     open var apiConfigurationKey: String { "default" }
//     open var method: HTTPEndpoint.HTTPMethod { .get }
//     open var path: String { "" }
//     public let requestData: Request

//     required public init(requestData: Request) {
//         self.requestData = requestData
//     }
// }

// public struct UserResponse: Decodable, Sendable {
//     /// Indicates if the request was successful.
//     let success: Bool
// }

// public class GetUserOperation: BaseAPIOperation<NoRequestData, UserResponse> {
//     override public var apiConfigurationKey: String { "userAPI" }
//     override public var method: HTTPEndpoint.HTTPMethod { .get }
//     override public var path: String { "/users" }
// }
