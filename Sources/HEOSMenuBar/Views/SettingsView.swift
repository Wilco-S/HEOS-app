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
        .frame(width: 480, height: 310)
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
