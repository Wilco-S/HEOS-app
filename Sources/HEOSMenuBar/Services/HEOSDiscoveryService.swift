@preconcurrency import Network
import Foundation

struct HEOSDevice: Identifiable, Equatable, Sendable {
    var id: String { endpoint.debugDescription }
    let name: String
    let host: String
    let port: UInt16
    let endpoint: NWEndpoint
}

final class HEOSDiscoveryService: @unchecked Sendable {
    var onDevicesChanged: (([HEOSDevice]) -> Void)?

    private let queue = DispatchQueue(label: "app.heos.discovery")
    private var browser: NWBrowser?

    func start() {
        stop()
        let browser = NWBrowser(for: .bonjour(type: "_heos-audio._tcp", domain: nil), using: .tcp)
        self.browser = browser
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let devices = results.compactMap(Self.device(from:)).sorted { $0.name < $1.name }
            DispatchQueue.main.async { [weak self] in self?.onDevicesChanged?(devices) }
        }
        browser.start(queue: queue)
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }

    private static func device(from result: NWBrowser.Result) -> HEOSDevice? {
        switch result.endpoint {
        case .service(let name, _, _, _):
            return HEOSDevice(
                name: name,
                host: "\(name).local",
                port: HEOSTCPClient.defaultPort,
                endpoint: result.endpoint
            )
        case .hostPort(let host, let port):
            return HEOSDevice(
                name: host.debugDescription,
                host: host.debugDescription,
                port: port.rawValue,
                endpoint: result.endpoint
            )
        default:
            return nil
        }
    }
}
