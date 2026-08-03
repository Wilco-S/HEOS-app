import Combine
import Foundation

@MainActor
final class HEOSAppModel: ObservableObject {
    @Published private(set) var connectionState: HEOSConnectionState = .disconnected
    @Published private(set) var players: [HEOSPlayer] = []
    @Published private(set) var discoveredDevices: [HEOSDevice] = []
    @Published var selectedPlayerID: Int?
    @Published var lastError: String?

    @Published var host: String {
        didSet {
            defaults.set(host, forKey: Keys.host)
        }
    }
    @Published var port: Int {
        didSet { defaults.set(port, forKey: Keys.port) }
    }
    @Published var reconnectAutomatically: Bool {
        didSet { defaults.set(reconnectAutomatically, forKey: Keys.reconnect) }
    }

    private enum Keys {
        static let host = "heos.host"
        static let port = "heos.port"
        static let reconnect = "heos.reconnect"
    }

    private let client: HEOSTCPClient
    private let discovery: HEOSDiscoveryService
    private let defaults: UserDefaults
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var userDisconnected = false
    private var hasStarted = false

    init(
        client: HEOSTCPClient = HEOSTCPClient(),
        discovery: HEOSDiscoveryService = HEOSDiscoveryService(),
        defaults: UserDefaults = .standard
    ) {
        self.client = client
        self.discovery = discovery
        self.defaults = defaults
        self.host = defaults.string(forKey: Keys.host) ?? ""
        let savedPort = defaults.integer(forKey: Keys.port)
        self.port = savedPort == 0 ? Int(HEOSTCPClient.defaultPort) : savedPort
        self.reconnectAutomatically = defaults.object(forKey: Keys.reconnect) as? Bool ?? true

        client.onStateChange = { [weak self] state in self?.handle(state: state) }
        client.onResponse = { [weak self] response in self?.handle(response: response) }
        discovery.onDevicesChanged = { [weak self] devices in
            self?.discoveredDevices = devices
            if self?.host.isEmpty == true, let device = devices.first {
                self?.connect(to: device)
            }
        }
    }

    var selectedPlayer: HEOSPlayer? {
        guard let selectedPlayerID else { return nil }
        return players.first { $0.id == selectedPlayerID }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        discovery.start()
        if !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { connect() }
    }

    func connect() {
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanHost.isEmpty else {
            lastError = "Vul het IP-adres of de hostnaam van een HEOS-apparaat in."
            return
        }
        userDisconnected = false
        reconnectTask?.cancel()
        client.connect(host: cleanHost, port: UInt16(clamping: port))
    }

    func connect(to device: HEOSDevice) {
        host = device.host
        port = Int(device.port)
        connect()
    }

    func disconnect() {
        userDisconnected = true
        reconnectTask?.cancel()
        client.disconnect()
        players = []
    }

    func refresh() {
        guard connectionState == .connected else { connect(); return }
        client.send(.getPlayers)
    }

    func select(_ player: HEOSPlayer) {
        selectedPlayerID = player.id
    }

    func setVolume(_ level: Int, for playerID: Int) {
        let level = min(max(level, 0), 100)
        updatePlayer(playerID) { $0.volume = level }
        client.send(.setVolume(playerID: playerID, level: level))
    }

    func setMuted(_ muted: Bool, for playerID: Int) {
        updatePlayer(playerID) { $0.isMuted = muted }
        client.send(.setMute(playerID: playerID, muted: muted))
    }

    private func handle(state: HEOSConnectionState) {
        connectionState = state
        switch state {
        case .connected:
            reconnectTask?.cancel()
            reconnectAttempt = 0
            lastError = nil
            client.send(.registerForEvents(true))
            client.send(.getPlayers)
        case .failed(let message):
            lastError = message
            scheduleReconnect()
        case .disconnected:
            if !userDisconnected { scheduleReconnect() }
        case .connecting:
            reconnectTask?.cancel()
        }
    }

    private func scheduleReconnect() {
        guard reconnectAutomatically, !userDisconnected, !host.isEmpty else { return }
        reconnectTask?.cancel()
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt - 1)), 30.0)
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.connect()
        }
    }

    private func handle(response: HEOSResponse) {
        let fields = response.heos.fields
        switch response.heos.command {
        case "player/get_players":
            let oldPlayers = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
            players = response.payloadObjects.compactMap(HEOSPlayer.init(payload:)).map { player in
                var player = player
                if let old = oldPlayers[player.id] {
                    player.volume = old.volume
                    player.isMuted = old.isMuted
                }
                return player
            }
            if selectedPlayerID == nil || !players.contains(where: { $0.id == selectedPlayerID }) {
                selectedPlayerID = players.first?.id
            }
            players.forEach {
                client.send(.getVolume(playerID: $0.id))
                client.send(.getMute(playerID: $0.id))
            }
        case "player/get_volume", "event/player_volume_changed":
            if let id = Int(fields["pid"] ?? ""), let level = Int(fields["level"] ?? "") {
                updatePlayer(id) { $0.volume = level }
            }
        case "player/get_mute", "event/player_mute_changed":
            if let id = Int(fields["pid"] ?? ""), let state = fields["state"] {
                updatePlayer(id) { $0.isMuted = state == "on" }
            }
        case "event/players_changed":
            client.send(.getPlayers)
        default:
            break
        }

        if !response.heos.succeeded, !response.heos.message.isEmpty {
            lastError = response.heos.message
        }
    }

    private func updatePlayer(_ id: Int, change: (inout HEOSPlayer) -> Void) {
        guard let index = players.firstIndex(where: { $0.id == id }) else { return }
        change(&players[index])
    }
}
