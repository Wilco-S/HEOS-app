import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: HEOSAppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 330)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HEOS").font(.headline)
                Text(statusText).font(.caption).foregroundStyle(statusColor)
            }
            Spacer()
            Button { model.refresh() } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
                .disabled(model.connectionState == .connecting)
                .help("Vernieuwen")
        }
        .padding(12)
    }

    @ViewBuilder
    private var content: some View {
        if model.connectionState == .connected, !model.players.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.players) { player in
                        PlayerRowView(
                            player: player,
                            isSelected: model.selectedPlayerID == player.id,
                            onSelect: { model.select(player) },
                            onVolumeChanged: { model.setVolume($0, for: player.id) },
                            onMuteChanged: { model.setMuted($0, for: player.id) }
                        )
                        if player.id != model.players.last?.id { Divider() }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(maxHeight: 420)
        } else {
            VStack(spacing: 10) {
                Image(systemName: emptyStateIcon).font(.system(size: 28)).foregroundStyle(.secondary)
                Text(emptyStateTitle).fontWeight(.medium)
                if let error = model.lastError {
                    Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                Button(model.connectionState == .connecting ? "Verbinden…" : "Verbinden") {
                    model.connect()
                }
                .disabled(model.connectionState == .connecting || model.host.isEmpty)
                if model.host.isEmpty {
                    Button("Configureer HEOS…") { openSettingsWindow() }
                        .buttonStyle(.link)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding(20)
        }
    }

    private var footer: some View {
        HStack {
            Button("Instellingen…") { openSettingsWindow() }.buttonStyle(.plain)
            Spacer()
            Button("Stop HEOS") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain)
        }
        .font(.caption)
        .padding(12)
    }

    private var statusText: String {
        switch model.connectionState {
        case .disconnected: return "Niet verbonden"
        case .connecting: return "Verbinden…"
        case .connected: return "Verbonden met \(model.host)"
        case .failed: return "Verbinding mislukt"
        }
    }

    private var statusColor: Color {
        model.connectionState == .connected ? .green : .secondary
    }

    private var emptyStateIcon: String {
        model.connectionState == .connected ? "hifispeaker.slash" : "wifi.exclamationmark"
    }

    private var emptyStateTitle: String {
        model.connectionState == .connected ? "Geen spelers gevonden" : "Geen HEOS-verbinding"
    }

    private func openSettingsWindow() {
        NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
