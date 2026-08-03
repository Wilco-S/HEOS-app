import Foundation

enum HEOSCommand: Equatable, Sendable {
    case getPlayers
    case registerForEvents(Bool)
    case getVolume(playerID: Int)
    case setVolume(playerID: Int, level: Int)
    case getMute(playerID: Int)
    case setMute(playerID: Int, muted: Bool)

    var wireValue: String {
        switch self {
        case .getPlayers:
            return "heos://player/get_players"
        case .registerForEvents(let enabled):
            let value = enabled ? "on" : "off"
            return "heos://system/register_for_change_events?enable=\(value)"
        case .getVolume(let playerID):
            return "heos://player/get_volume?pid=\(playerID)"
        case .setVolume(let playerID, let level):
            return "heos://player/set_volume?pid=\(playerID)&level=\(min(max(level, 0), 100))"
        case .getMute(let playerID):
            return "heos://player/get_mute?pid=\(playerID)"
        case .setMute(let playerID, let muted):
            let value = muted ? "on" : "off"
            return "heos://player/set_mute?pid=\(playerID)&state=\(value)"
        }
    }

    var data: Data { Data((wireValue + "\r\n").utf8) }
}
