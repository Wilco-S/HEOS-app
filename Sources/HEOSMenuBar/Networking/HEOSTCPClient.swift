@preconcurrency import Network
import Foundation

enum HEOSConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

final class HEOSTCPClient: @unchecked Sendable {
    static let defaultPort: UInt16 = 1255

    var onStateChange: ((HEOSConnectionState) -> Void)?
    var onResponse: ((HEOSResponse) -> Void)?

    private let queue = DispatchQueue(label: "app.heos.tcp", qos: .userInitiated)
    private var connection: NWConnection?
    private var connectionTimeout: DispatchWorkItem?
    private var receiveBuffer = Data()

    func connect(host: String, port: UInt16 = defaultPort) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            publish(state: .failed("Ongeldige poort: \(port)"))
            return
        }

        start(NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp))
    }

    private func start(_ newConnection: NWConnection) {
        connectionTimeout?.cancel()
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        receiveBuffer.removeAll(keepingCapacity: false)

        publish(state: .connecting)
        connection = newConnection
        newConnection.stateUpdateHandler = { [weak self, weak newConnection] state in
            guard let self, newConnection === self.connection else { return }
            switch state {
            case .ready:
                self.connectionTimeout?.cancel()
                self.publish(state: .connected)
                self.receiveNext()
            case .failed(let error):
                self.connectionTimeout?.cancel()
                self.publish(state: .failed(error.localizedDescription))
                self.connection = nil
            case .cancelled:
                self.connectionTimeout?.cancel()
                self.publish(state: .disconnected)
            default:
                break
            }
        }
        newConnection.start(queue: queue)

        let timeout = DispatchWorkItem { [weak self, weak newConnection] in
            guard let self, newConnection === self.connection else { return }
            newConnection?.stateUpdateHandler = nil
            newConnection?.cancel()
            self.connection = nil
            self.publish(state: .failed("Verbinding time-out. Controleer het IP-adres en poort 1255."))
        }
        connectionTimeout = timeout
        queue.asyncAfter(deadline: .now() + 8, execute: timeout)
    }

    func disconnect() {
        connectionTimeout?.cancel()
        connectionTimeout = nil
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
        receiveBuffer.removeAll(keepingCapacity: false)
        publish(state: .disconnected)
    }

    func send(_ command: HEOSCommand) {
        queue.async { [weak self] in
            self?.connection?.send(content: command.data, completion: .contentProcessed { [weak self] error in
                if let error { self?.publish(state: .failed(error.localizedDescription)) }
            })
        }
    }

    private func receiveNext() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, complete, error in
            guard let self else { return }
            if let data { self.consume(data) }
            if let error {
                self.publish(state: .failed(error.localizedDescription))
                return
            }
            if complete {
                self.publish(state: .disconnected)
                return
            }
            self.receiveNext()
        }
    }

    private func consume(_ data: Data) {
        receiveBuffer.append(data)
        let delimiter = Data("\r\n".utf8)
        while let range = receiveBuffer.range(of: delimiter) {
            let line = receiveBuffer.subdata(in: receiveBuffer.startIndex..<range.lowerBound)
            receiveBuffer.removeSubrange(receiveBuffer.startIndex..<range.upperBound)
            guard !line.isEmpty, let response = try? HEOSResponse.decode(line: line) else { continue }
            DispatchQueue.main.async { [weak self] in self?.onResponse?(response) }
        }
    }

    private func publish(state: HEOSConnectionState) {
        DispatchQueue.main.async { [weak self] in self?.onStateChange?(state) }
    }
}
