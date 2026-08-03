import XCTest
@testable import HEOSMenuBar

final class HEOSProtocolTests: XCTestCase {
    func testDecodesPlayersResponse() throws {
        let json = #"{"heos":{"command":"player/get_players","result":"success","message":""},"payload":[{"name":"Woonkamer","pid":"1","model":"HEOS 5","version":"3.34","ip":"192.168.1.20","network":"wired","lineout":"0"}]}"#
        let response = try HEOSResponse.decode(line: Data(json.utf8))

        XCTAssertTrue(response.heos.succeeded)
        XCTAssertEqual(response.payloadObjects.count, 1)
        let player = try XCTUnwrap(HEOSPlayer(payload: response.payloadObjects[0]))
        XCTAssertEqual(player.id, 1)
        XCTAssertEqual(player.name, "Woonkamer")
        XCTAssertEqual(player.ipAddress, "192.168.1.20")
    }

    func testParsesMessageFieldsAndPercentEncoding() throws {
        let json = #"{"heos":{"command":"event/player_volume_changed","result":"success","message":"pid=42&name=Living%20Room&level=37&mute=off"}}"#
        let response = try HEOSResponse.decode(line: Data(json.utf8))

        XCTAssertEqual(response.heos.fields["pid"], "42")
        XCTAssertEqual(response.heos.fields["name"], "Living Room")
        XCTAssertEqual(response.heos.fields["level"], "37")
    }

    func testCommandsUseCRLFAndClampVolume() {
        XCTAssertEqual(HEOSCommand.getPlayers.wireValue, "heos://player/get_players")
        XCTAssertEqual(
            HEOSCommand.setVolume(playerID: 7, level: 140).wireValue,
            "heos://player/set_volume?pid=7&level=100"
        )
        XCTAssertEqual(String(data: HEOSCommand.setMute(playerID: 7, muted: true).data, encoding: .utf8),
                       "heos://player/set_mute?pid=7&state=on\r\n")
    }
}
