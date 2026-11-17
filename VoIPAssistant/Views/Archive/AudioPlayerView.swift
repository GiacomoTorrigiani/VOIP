import SwiftUI

public struct AudioPlayerView: View {
    @ObservedObject var playerManager: AudioPlayerManager
    let audioURL: URL?

    public init(playerManager: AudioPlayerManager, audioURL: URL?) {
        self.playerManager = playerManager
        self.audioURL = audioURL
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Play / Pause Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let url = audioURL {
                        playerManager.loadAudio(from: url)
                        playerManager.togglePlayPause()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 48, height: 48)

                        if playerManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .offset(x: playerManager.isPlaying ? 0 : 2)
                        }
                    }
                }
                .disabled(audioURL == nil)

                // Slider & Time
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { playerManager.currentTime },
                            set: { newValue in playerManager.seek(to: newValue) }
                        ),
                        in: 0...max(playerManager.duration, 1.0)
                    )
                    .accentColor(.blue)

                    HStack {
                        Text(playerManager.formatTime(playerManager.currentTime))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(playerManager.formatTime(playerManager.duration))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let error = playerManager.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .onAppear {
            if let url = audioURL {
                playerManager.loadAudio(from: url)
            }
        }
        .onDisappear {
            playerManager.pause()
        }
    }
}
