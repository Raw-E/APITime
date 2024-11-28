import Foundation
import LoggingTime

struct URLRequestConfigurator {
    let encoder: JSONEncoder

    init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }

    func configure(_ request: inout URLRequest, with dataModel: any HTTPRequestDataModel) throws {
        configureHeaders(for: &request, with: dataModel)
        try configureBody(for: &request, with: dataModel)
        configureQueryItems(for: &request, with: dataModel)
    }

    private func configureHeaders(for request: inout URLRequest, with dataModel: any HTTPRequestDataModel) {
        guard let headersModel = dataModel as? HTTPRequestHeaders else { return }
        for (key, value) in headersModel.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func configureBody(for request: inout URLRequest, with dataModel: any HTTPRequestDataModel) throws {
        guard let bodyModel = dataModel as? any HTTPRequestBody else { return }
        PreviewLogger.log("Body before encoding: \(bodyModel.body)", level: .debug)
        let bodyData = try bodyModel.encodeBody(with: encoder)
        request.httpBody = bodyData
        PreviewLogger.log("Body after encoding: \(String(data: bodyData, encoding: .utf8) ?? "Unable to convert data to string")", level: .debug)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func configureQueryItems(for request: inout URLRequest, with dataModel: any HTTPRequestDataModel) {
        guard let queryModel = dataModel as? HTTPRequestQueryItems,
              !queryModel.queryItems.isEmpty,
              let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        components.queryItems = queryModel.queryItems
        request.url = components.url
    }
}