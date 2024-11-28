import Foundation

public protocol HTTPRequestDataModel {}

public struct NoRequestData: HTTPRequestDataModel {
    public init() {}
}

public protocol HTTPRequestHeaders {
    var headers: [String: String] { get }
}

public extension HTTPRequestHeaders {
    var headers: [String: String] { [:] }
}

public protocol HTTPRequestQueryItems {
    var queryItems: [URLQueryItem] { get }
}

public extension HTTPRequestQueryItems {
    var queryItems: [URLQueryItem] { [] }
}

public protocol HTTPRequestBody {
    associatedtype Body: Encodable
    var body: Body { get }
    
    func encodeBody(with encoder: JSONEncoder) throws -> Data
}

public extension HTTPRequestBody {
    func encodeBody(with encoder: JSONEncoder) throws -> Data {
        try encoder.encode(body)
    }
}
