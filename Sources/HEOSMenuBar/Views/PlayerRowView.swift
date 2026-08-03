import Foundation
import SwiftUI

struct PlayerRowView: View {
    let player: HEOSPlayer
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
    let onVolumeChanged: (Int) -> Void
    let onMuteChanged: (Bool) -> Void
    let dragProvider: () -> NSItemProvider

    @State private var volume: Double

    init(
        player: HEOSPlayer,
        isSelected: Bool,
        isEnabled: Bool,
        onSelect: @escaping () -> Void,
        onVolumeChanged: @escaping (Int) -> Void,
        onMuteChanged: @escaping (Bool) -> Void,
        dragProvider: @escaping () -> NSItemProvider
    ) {
        self.player = player
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.onSelect = onSelect
        self.onVolumeChanged = onVolumeChanged
        self.onMuteChanged = onMuteChanged
        self.dragProvider = dragProvider
        _volume = State(initialValue: Double(player.volume))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: isSelected ? "hifispeaker.2.fill" : "hifispeaker.2")
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(player.name).fontWeight(.medium)
                            if !player.model.isEmpty {
                                Text(player.model).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .frame(maxWidth: .infinity, alignment: .leading)

                if isEnabled {
                    Text("\(Int(volume))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Uitgeschakeld")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, height: 28)
                    .contentShape(Rectangle())
                    .onDrag(dragProvider)
                    .help("Sleep om de volgorde te wijzigen")
            }

            HStack(spacing: 10) {
                Button {
                    onMuteChanged(!player.isMuted)
                } label: {
                    Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .frame(width: 18)
                }
                .buttonStyle(.borderless)
                .help(player.isMuted ? "Geluid aan" : "Dempen")

                Slider(value: $volume, in: 0...100, step: 1) { editing in
                    if !editing { onVolumeChanged(Int(volume)) }
                }
                .onChange(of: player.volume) { volume = Double($0) }
            }
            .disabled(!isEnabled)
        }
        .padding(.vertical, 6)
        .opacity(isEnabled ? 1 : 0.45)
    }
}
