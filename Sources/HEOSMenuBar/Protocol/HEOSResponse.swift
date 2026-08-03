import Foundation

struct HEOSResponse: Decodable, Equatable, Sendable {
    struct Header: Decodable, Equatable, Sendable {
        let command: String
        let result: String
        let message: String

        var succeeded: Bool { result == "success" }

        var fields: [String: String] {
            message.split(separator: "&").reduce(into: [:]) { result, pair in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return }
                result[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
            }
        }
    }

    let heos: Header
    let payload: JSONValue?

    var payloadObjects: [[String: JSONValue]] {
        guard case .array(let items) = payload else { return [] }
        return items.compactMap(\.objectValue)
    }

    static func decode(line: Data) throws -> HEOSResponse {
        try JSONDecoder().decode(HEOSResponse.self, from: line)
    }
}
