import Combine
import Foundation

@MainActor
final class HEOSAppModel: ObservableObject {
    @Published private(set) var connectionState: HEOSConnectionState = .disconnected
    @Published private(set) var players: [HEOSPlayer] = []
    @Published private(set) var discoveredDevices: [HEOSDevice] = []
    @Published private(set) var disabledPlayerIDs: Set<Int> = []
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
        static let disabledPlayers = "heos.disabledPlayers"
        static let playerOrder = "heos.playerOrder"
    }

    private let client: HEOSTCPClient
    private let discovery: HEOSDiscoveryService
    private let defaults: UserDefaults
    private var playerOrder: [Int]
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
        let savedHost = defaults.string(forKey: Keys.host) ?? ""
        // Versions before 0.1.1 saved the Bonjour service name as a host
        // (for example `HEOS Bar.local`). DNS hostnames cannot contain spaces.
        self.host = savedHost.contains(where: \.isWhitespace) ? "" : savedHost
        let savedPort = defaults.integer(forKey: Keys.port)
        self.port = savedPort == 0 ? Int(HEOSTCPClient.defaultPort) : savedPort
        self.reconnectAutomatically = defaults.object(forKey: Keys.reconnect) as? Bool ?? true
        self.disabledPlayerIDs = Set(defaults.array(forKey: Keys.disabledPlayers) as? [Int] ?? [])
        self.playerOrder = defaults.array(forKey: Keys.playerOrder) as? [Int] ?? []

        client.onStateChange = { [weak self] state in self?.handle(state: state) }
        client.onResponse = { [weak self] response in self?.handle(response: response) }
        discovery.onDevicesChanged = { [weak self] devices in
            self?.discoveredDevices = devices
            let shouldReplaceLegacyHost = self?.host.lowercased().hasSuffix(".local") == true
            if (self?.host.isEmpty == true || shouldReplaceLegacyHost), let device = devices.first {
                self?.connect(to: device)
            }
        }
    }

    var selectedPlayer: HEOSPlayer? {
        guard let selectedPlayerID else { return nil }
        return players.first { $0.id == selectedPlayerID && isPlayerEnabled($0.id) }
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
        guard isPlayerEnabled(player.id) else { return }
        selectedPlayerID = player.id
    }

    func setVolume(_ level: Int, for playerID: Int) {
        guard isPlayerEnabled(playerID) else { return }
        let level = min(max(level, 0), 100)
        updatePlayer(playerID) { $0.volume = level }
        client.send(.setVolume(playerID: playerID, level: level))
    }

    func setMuted(_ muted: Bool, for playerID: Int) {
        guard isPlayerEnabled(playerID) else { return }
        updatePlayer(playerID) { $0.isMuted = muted }
        client.send(.setMute(playerID: playerID, muted: muted))
    }

    func isPlayerEnabled(_ playerID: Int) -> Bool {
        !disabledPlayerIDs.contains(playerID)
    }

    func setPlayerEnabled(_ enabled: Bool, for playerID: Int) {
        if enabled {
            disabledPlayerIDs.remove(playerID)
        } else {
            disabledPlayerIDs.insert(playerID)
        }
        defaults.set(disabledPlayerIDs.sorted(), forKey: Keys.disabledPlayers)

        if selectedPlayerID == playerID, !enabled {
            selectedPlayerID = players.first { isPlayerEnabled($0.id) }?.id
        }
    }

    func movePlayer(_ playerID: Int, relativeTo destinationID: Int) {
        let currentIDs = players.map(\.id)
        let reorderedIDs = Self.reorderedPlayerIDs(
            currentIDs,
            moving: playerID,
            relativeTo: destinationID
        )
        guard reorderedIDs != currentIDs else { return }

        let playersByID = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        players = reorderedIDs.compactMap { playersByID[$0] }

        let visibleIDs = Set(reorderedIDs)
        playerOrder = reorderedIDs + playerOrder.filter { !visibleIDs.contains($0) }
        defaults.set(playerOrder, forKey: Keys.playerOrder)
    }

    static func reorderedPlayerIDs(
        _ playerIDs: [Int],
        moving playerID: Int,
        relativeTo destinationID: Int
    ) -> [Int] {
        guard
            let sourceIndex = playerIDs.firstIndex(of: playerID),
            let destinationIndex = playerIDs.firstIndex(of: destinationID),
            sourceIndex != destinationIndex
        else { return playerIDs }

        var result = playerIDs
        result.remove(at: sourceIndex)
        guard let updatedDestinationIndex = result.firstIndex(of: destinationID) else {
            return playerIDs
        }

        let insertionIndex = sourceIndex < destinationIndex
            ? updatedDestinationIndex + 1
            : updatedDestinationIndex
        result.insert(playerID, at: insertionIndex)
        return result
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
            var receivedPlayers = response.payloadObjects.compactMap(HEOSPlayer.init(payload:)).map { player in
                var player = player
                if let old = oldPlayers[player.id] {
                    player.volume = old.volume
                    player.isMuted = old.isMuted
                }
                return player
            }
            let newPlayerIDs = receivedPlayers.map(\.id).filter { !playerOrder.contains($0) }
            if !newPlayerIDs.isEmpty {
                playerOrder.append(contentsOf: newPlayerIDs)
                defaults.set(playerOrder, forKey: Keys.playerOrder)
            }
            let orderIndex = Dictionary(uniqueKeysWithValues: playerOrder.enumerated().map { ($0.element, $0.offset) })
            receivedPlayers.sort {
                orderIndex[$0.id, default: .max] < orderIndex[$1.id, default: .max]
            }
            players = receivedPlayers
            if selectedPlayerID == nil || !players.contains(where: {
                $0.id == selectedPlayerID && isPlayerEnabled($0.id)
            }) {
                selectedPlayerID = players.first { isPlayerEnabled($0.id) }?.id
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
