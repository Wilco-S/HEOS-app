import Darwin
import Foundation

struct HEOSDevice: Identifiable, Equatable, Sendable {
    var id: String { host }
    let name: String
    let host: String
    let port: UInt16
}

final class HEOSDiscoveryService: NSObject, @unchecked Sendable {
    var onDevicesChanged: (([HEOSDevice]) -> Void)?

    private let browser = NetServiceBrowser()
    private var services: [String: NetService] = [:]
    private var devices: [String: HEOSDevice] = [:]

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        stop()
        browser.searchForServices(ofType: "_heos-audio._tcp.", inDomain: "local.")
    }

    func stop() {
        browser.stop()
        services.values.forEach { $0.stop() }
        services.removeAll()
        devices.removeAll()
    }

    private func publishDevices() {
        onDevicesChanged?(devices.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }

    static func ipv4Address(from addresses: [Data]?) -> String? {
        addresses?.lazy.compactMap { address in
            address.withUnsafeBytes { buffer -> String? in
                guard let baseAddress = buffer.baseAddress else { return nil }
                let socketAddress = baseAddress.assumingMemoryBound(to: sockaddr.self)
                guard Int32(socketAddress.pointee.sa_family) == AF_INET else { return nil }

                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    socketAddress,
                    socklen_t(buffer.count),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                guard result == 0 else { return nil }
                return String(cString: host)
            }
        }.first
    }
}

extension HEOSDiscoveryService: NetServiceBrowserDelegate, NetServiceDelegate {
    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        services[service.name] = service
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        services.removeValue(forKey: service.name)
        devices.removeValue(forKey: service.name)
        if !moreComing { publishDevices() }
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let resolvedHost = Self.ipv4Address(from: sender.addresses) else {
            return
        }

        // `_heos-audio._tcp` advertises HEOS' internal communications port
        // (commonly 10101). Resolve its concrete IPv4 address, then connect
        // to the command-line JSON API on port 1255.
        devices[sender.name] = HEOSDevice(
            name: sender.name,
            host: resolvedHost,
            port: HEOSTCPClient.defaultPort
        )
        publishDevices()
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        services.removeValue(forKey: sender.name)
    }
}
