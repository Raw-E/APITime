import Foundation

public struct APIConfiguration: Sendable {
    let key: String
    let apiBaseURL: URL

    public init(key: String, apiBaseURL: URL) {
        self.key = key
        self.apiBaseURL = apiBaseURL
    }
}

public actor APIConfigurations {
    private var configurations: [String: APIConfiguration] = [:]

    private init() {}

    public static let shared = APIConfigurations()

    public func addConfiguration(_ configuration: APIConfiguration) {
        configurations[configuration.key] = configuration
    }

    public func getConfiguration(forKey key: String) -> APIConfiguration? {
        return configurations[key]
    }
}

public func registerAPIConfiguration(_ configuration: APIConfiguration) async {
    await APIConfigurations.shared.addConfiguration(configuration)
}
