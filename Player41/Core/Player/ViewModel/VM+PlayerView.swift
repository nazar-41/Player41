//
//  VM+PlayerView.swift
//  Player41
//
//  Created by Nazar Velkakayev on 09.11.2024.
//

import Foundation
import AVFoundation
import Combine

class VM_PlayerView: ObservableObject {
    @Published var song: SongModel = .init(){
        didSet { setupListeners() }
    }
    @Published var player: AVPlayer?
    @Published var playerStatus: Enum_PlayerState = .paused
    @Published var currentTime: Double = 0
    @Published var totalDuration: Double = 0
    @Published var bufferProgress: Double = 0 // 0.0 to 1.0
    @Published var maxBufferDuration: Double = 30 // seconds

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        initPlayer()
        setupListeners()
        setMaxBufferDuration()
    }

    deinit {
        removeTimeObserver()
    }

    private func setupListeners() {
        removeListeners()
        playerStatusListener()
        playerErrorListener()
        playerTotalDurationListener()
        playerBufferListener()
        playerTimeObserver()
    }

    private func removeListeners() {
        cancellables.removeAll()
    }
    
    private func initPlayer(){
        guard player == nil, let url = song.url else{return}
    
        player = .init(url: url)
    }

    private func playerStatusListener() {
        player?.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                self?.updatePlayerStatus(for: status)
            }
            .store(in: &cancellables)
    }

    private func updatePlayerStatus(for status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            playerStatus = .playing
        case .paused:
            playerStatus = .paused
        case .waitingToPlayAtSpecifiedRate:
            playerStatus = .loading
        @unknown default:
            break
        }
    }

    private func playerErrorListener() {
        player?.publisher(for: \.status)
            .sink { [weak self] status in
                self?.handlePlayerError(for: status)
            }
            .store(in: &cancellables)
    }

    private func handlePlayerError(for status: AVPlayer.Status) {
        if status == .failed {
            playerStatus = .error("FAILED")
        }
        if let error = player?.currentItem?.error {
            playerStatus = .error(error.localizedDescription)
        }
    }

    private func playerTotalDurationListener() {
        player?.publisher(for: \.currentItem?.duration)
            .compactMap { $0?.seconds }
            .sink { [weak self] duration in
                self?.totalDuration = duration
            }
            .store(in: &cancellables)
    }

    private func playerBufferListener() {
        player?.publisher(for: \.currentItem?.loadedTimeRanges)
            .sink { [weak self] timeRanges in
                self?.updateBufferProgress(timeRanges)
            }
            .store(in: &cancellables)
    }

    private func playerTimeObserver() {
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func updateBufferProgress(_ timeRanges: [NSValue]?) {
        guard let timeRanges = timeRanges,
              let firstRange = timeRanges.first?.timeRangeValue,
              totalDuration > 0 else {
            bufferProgress = 0
            return
        }
        
        let bufferedTime = CMTimeGetSeconds(firstRange.start) + CMTimeGetSeconds(firstRange.duration)
        
        // If the buffer is very close to totalDuration, set progress to 1.0
        if abs(bufferedTime - totalDuration) < 0.5 {
            bufferProgress = 1.0
        } else {
            bufferProgress = bufferedTime / totalDuration
        }
    }



    private func setMaxBufferDuration() {
        player?.currentItem?.preferredForwardBufferDuration = maxBufferDuration
    }

    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }
}
