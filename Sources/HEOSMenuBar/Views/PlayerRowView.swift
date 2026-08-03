import SwiftUI

struct PlayerRowView: View {
    let player: HEOSPlayer
    let isSelected: Bool
    let onSelect: () -> Void
    let onVolumeChanged: (Int) -> Void
    let onMuteChanged: (Bool) -> Void

    @State private var volume: Double

    init(
        player: HEOSPlayer,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onVolumeChanged: @escaping (Int) -> Void,
        onMuteChanged: @escaping (Bool) -> Void
    ) {
        self.player = player
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onVolumeChanged = onVolumeChanged
        self.onMuteChanged = onMuteChanged
        _volume = State(initialValue: Double(player.volume))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    Text("\(Int(volume))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
        }
        .padding(.vertical, 6)
    }
}
