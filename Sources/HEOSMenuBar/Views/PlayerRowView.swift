import SwiftUI

struct PlayerRowView: View {
    let player: HEOSPlayer
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
    let onVolumeChanged: (Int) -> Void
    let onMuteChanged: (Bool) -> Void
    let isReordering: Bool
    let onReorderChanged: (CGFloat) -> Void
    let onReorderEnded: () -> Void

    @State private var volume: Double

    init(
        player: HEOSPlayer,
        isSelected: Bool,
        isEnabled: Bool,
        onSelect: @escaping () -> Void,
        onVolumeChanged: @escaping (Int) -> Void,
        onMuteChanged: @escaping (Bool) -> Void,
        isReordering: Bool,
        onReorderChanged: @escaping (CGFloat) -> Void,
        onReorderEnded: @escaping () -> Void
    ) {
        self.player = player
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.onSelect = onSelect
        self.onVolumeChanged = onVolumeChanged
        self.onMuteChanged = onMuteChanged
        self.isReordering = isReordering
        self.onReorderChanged = onReorderChanged
        self.onReorderEnded = onReorderEnded
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
                    .foregroundStyle(isReordering ? Color.accentColor : Color.secondary)
                    .frame(width: 20, height: 28)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .named("playerList"))
                            .onChanged { onReorderChanged($0.location.y) }
                            .onEnded { _ in onReorderEnded() }
                    )
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

                Button {
                    adjustVolume(by: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(volume <= 0)
                .help("Volume 1% zachter")

                Slider(value: $volume, in: 0...100, step: 1) { editing in
                    if !editing { onVolumeChanged(Int(volume)) }
                }
                .onChange(of: player.volume) { volume = Double($0) }

                Button {
                    adjustVolume(by: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .disabled(volume >= 100)
                .help("Volume 1% harder")
            }
            .disabled(!isEnabled)
        }
        .padding(.vertical, 6)
        .background(isReordering ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func adjustVolume(by change: Int) {
        let adjustedVolume = min(max(Int(volume) + change, 0), 100)
        guard adjustedVolume != Int(volume) else { return }
        volume = Double(adjustedVolume)
        onVolumeChanged(adjustedVolume)
    }
}
