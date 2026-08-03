import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: HEOSAppModel

    var body: some View {
        Form {
            Section("Verbinding") {
                TextField("IP-adres of hostnaam", text: $model.host)
                    .textFieldStyle(.roundedBorder)
                TextField("Poort", value: $model.port, format: .number)
                    .textFieldStyle(.roundedBorder)
                Toggle("Automatisch opnieuw verbinden", isOn: $model.reconnectAutomatically)
                HStack {
                    if model.connectionState == .connected {
                        Button("Verbreek verbinding") { model.disconnect() }
                    } else {
                        Button("Verbind") { model.connect() }.disabled(model.host.isEmpty)
                    }
                    Spacer()
                    Text(connectionLabel).foregroundStyle(.secondary)
                }
            }

            if !model.players.isEmpty {
                Section {
                    ForEach(model.players) { player in
                        Toggle(isOn: Binding(
                            get: { model.isPlayerEnabled(player.id) },
                            set: { model.setPlayerEnabled($0, for: player.id) }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                if !player.model.isEmpty {
                                    Text(player.model).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Bedienbare spelers")
                } footer: {
                    Text("Uitgeschakelde spelers blijven gewoon werken in HEOS en andere apps, maar kunnen vanuit deze app niet worden bediend.")
                }
            }

            if !model.discoveredDevices.isEmpty {
                Section("Gevonden apparaten") {
                    ForEach(model.discoveredDevices) { device in
                        Button {
                            model.connect(to: device)
                        } label: {
                            HStack {
                                Image(systemName: "hifispeaker")
                                Text(device.name)
                                Spacer()
                                Text(device.host).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 500)
        .background(SettingsWindowConfigurator().frame(width: 0, height: 0))
    }

    private var connectionLabel: String {
        switch model.connectionState {
        case .disconnected: return "Niet verbonden"
        case .connecting: return "Verbinden…"
        case .connected: return "Verbonden"
        case .failed: return "Mislukt"
        }
    }
}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        FloatingSettingsView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.window?.level = .floating
    }
}

private final class FloatingSettingsView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.level = .floating
    }
}
