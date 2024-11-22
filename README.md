# Video Player Example

This is a simple iOS project that demonstrates how to handle video player states, download HLS live streams, and play them locally. The app includes:

- **Player State Handling**: Demonstrates managing player states like playing, paused, loading, and error.
- **Custom Slider**: Allows seeking through the video and displays the current playback time.
- **Buffering**: Shows real-time buffer progress with a customizable buffer duration.
- **HLS Stream Download**: Allows downloading HLS `.m3u8` streams for offline use, including both video and audio streams.

## Screenshots

| ![img-1](https://github.com/user-attachments/assets/ec694f6b-558e-4702-9bf7-e584be3fdbf8) | ![img-2](https://github.com/user-attachments/assets/65a89bf9-716d-451d-8219-4411c9dd4b9d) | ![img-3](https://github.com/user-attachments/assets/ac2761f2-0c02-46ed-bd34-7b8f44f7fdeb) |
|:------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------:|
| Playing and Buffering Process                                                              | Downloading Stream                                                                         | Offline Playback                                                                                |


## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/nazar-41/Player41.git
   ```
2. Open `Player41.xcodeproj` in Xcode.
3. Build and run on an iOS device or simulator.

---

## How It Works

### State Handling
The app uses an `Enum_PlayerState` to manage the four playback states:

```swift
enum Enum_PlayerState {
    case playing
    case paused
    case loading
    case error(String)
}
```

The state is updated dynamically based on the `AVPlayer`'s status:

```swift
player?.publisher(for: \.timeControlStatus)
    .sink { [weak self] status in
        switch status {
        case .playing:
            self?.playerStatus = .playing
        case .paused:
            self?.playerStatus = .paused
        case .waitingToPlayAtSpecifiedRate:
            self?.playerStatus = .loading
        @unknown default:
            break
        }
    }
    .store(in: &cancellables)
```

---

### Custom Slider
The app includes a slider to scrub through the video timeline. The slider reflects the `currentTime` and `totalDuration` dynamically:

```swift
Slider(
    value: $viewModel.currentTime,
    in: 0...(viewModel.totalDuration > 0 ? viewModel.totalDuration : 1),
    onEditingChanged: { isDragging in
        if isDragging {
            viewModel.pause()
        } else {
            viewModel.seek(to: viewModel.currentTime)
            viewModel.play()
        }
    }
)
```

---

### Buffer Handling
The buffer progress is calculated using the `loadedTimeRanges` of the player's `currentItem`:

```swift
player?.publisher(for: \.currentItem?.loadedTimeRanges)
    .sink { [weak self] timeRanges in
        guard let self = self else { return }
        self.updateBufferProgress(timeRanges)
    }
    .store(in: &cancellables)

private func updateBufferProgress(_ timeRanges: [NSValue]?) {
    guard let timeRanges = timeRanges,
          let firstRange = timeRanges.first?.timeRangeValue,
          totalDuration > 0 else {
        bufferProgress = 0
        return
    }

    let bufferedTime = CMTimeGetSeconds(firstRange.start) + CMTimeGetSeconds(firstRange.duration)
    bufferProgress = bufferedTime / totalDuration
}
```

---

### Download Feature
The app supports downloading HLS streams using the following logic:

- Start downloading a stream:
  ```swift
  func downloadAsset(_ asset: Asset) {
      AssetPersistenceManager.sharedManager.downloadStream(asset.stream)
  }
  ```

- Cancel a download:
  ```swift
  func cancelDownload(_ asset: Asset) {
      AssetPersistenceManager.sharedManager.cancelDownload(for: asset.stream)
  }
  ```

- Delete a downloaded stream:
  ```swift
  func deleteAsset(_ asset: Asset) {
      AssetPersistenceManager.sharedManager.deleteAsset(asset)
  }
  ```

The UI provides a seamless way to download, cancel, and delete streams.

---

## Note

The download logic for HLS streams was taken from Apple's official example on how to handle media downloading in iOS apps. It demonstrates how to download, cache, and play HLS streams locally, and is implemented using `AVAssetDownloadURLSession` for efficient downloading.


## Author
Developed by [Nazar Velkakayev](https://github.com/nazar-41)
