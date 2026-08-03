import Foundation

struct HEOSPlayer: Identifiable, Equatable, Sendable {
    let id: Int
    var name: String
    var model: String
    var version: String
    var ipAddress: String
    var network: String
    var lineOut: Int
    var volume: Int
    var isMuted: Bool

    init(
        id: Int,
        name: String,
        model: String = "",
        version: String = "",
        ipAddress: String = "",
        network: String = "",
        lineOut: Int = 0,
        volume: Int = 0,
        isMuted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.version = version
        self.ipAddress = ipAddress
        self.network = network
        self.lineOut = lineOut
        self.volume = volume
        self.isMuted = isMuted
    }

    init?(payload: [String: JSONValue]) {
        guard
            let playerID = payload["pid"]?.intValue,
            let name = payload["name"]?.stringValue
        else { return nil }

        self.init(
            id: playerID,
            name: name,
            model: payload["model"]?.stringValue ?? "",
            version: payload["version"]?.stringValue ?? "",
            ipAddress: payload["ip"]?.stringValue ?? "",
            network: payload["network"]?.stringValue ?? "",
            lineOut: payload["lineout"]?.intValue ?? 0
        )
    }
}
