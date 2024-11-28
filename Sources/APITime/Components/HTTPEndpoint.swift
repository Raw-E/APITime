import Foundation

public struct HTTPEndpoint: Sendable {
    public enum HTTPMethod: String, Sendable {
        case get, post, put, delete
        public var rawValue: String { String(describing: self).uppercased() }
    }

    let method: HTTPMethod
    let baseURL: URL
    let path: String
    
    public init(method: HTTPMethod, baseURL: URL, path: String) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
    }
    
    var url: URL {
        baseURL.appendingPathComponent(path)
    }
}
