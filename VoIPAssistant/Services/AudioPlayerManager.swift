import Foundation
import AVFoundation
import Combine

public final class AudioPlayerManager: ObservableObject {
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemStatusObserver: AnyCancellable?
    private var currentURL: URL?

    public init() {
        configureAudioSession()
    }

    deinit {
        cleanup()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Avviso: Impossibile configurare AVAudioSession: \(error.localizedDescription)")
        }
    }

    public func loadAudio(from url: URL) {
        if currentURL == url && player != nil {
            return
        }

        cleanup()
        currentURL = url
        isLoading = true
        errorMessage = nil

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Osserva la durata
        itemStatusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    let dur = playerItem.duration.seconds
                    if !dur.isNaN && dur > 0 {
                        self.duration = dur
                    }
                case .failed:
                    self.isLoading = false
                    self.errorMessage = playerItem.error?.localizedDescription ?? "Errore nel caricamento dell'audio"
                default:
                    break
                }
            }

        // Osserva il progresso temporale (ogni 0.25 secondi)
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = time.seconds
            if !seconds.isNaN {
                self.currentTime = seconds
            }
        }

        // Fine riproduzione
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.seek(to: 0)
        }
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func play() {
        guard let player = player else { return }
        player.play()
        isPlaying = true
    }

    public func pause() {
        guard let player = player else { return }
        player.pause()
        isPlaying = false
    }

    public func seek(to seconds: Double) {
        guard let player = player else { return }
        let targetTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
    }

    public func cleanup() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        itemStatusObserver?.cancel()
        itemStatusObserver = nil
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        isLoading = false
    }

    public func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
