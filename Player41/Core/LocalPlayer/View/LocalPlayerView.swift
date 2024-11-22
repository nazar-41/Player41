//
//  LocalPlayerView.swift
//  Player41
//
//  Created by Nazar Velkakayev on 21.11.2024.
//

import SwiftUI
import AVKit

struct LocalPlayerView: View {
    let song: SongModel
    @State private var player: AVPlayer?
    @State private var localURL: String?
    
    var body: some View {
        VStack {
            Text(localURL ?? "No Local Asset")
                .padding()
            
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        player.play()
                    }
            } else {
                Text("Unable to load video.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let stream = song.asset?.stream else { return }
        
        if let localAsset = AssetPersistenceManager.sharedManager.localAssetForStream(with: stream) {
            DispatchQueue.main.async {
                self.localURL = localAsset.urlAsset.url.absoluteString
                self.player = AVPlayer(playerItem: AVPlayerItem(asset: localAsset.urlAsset))
            }
        } else {
            DispatchQueue.main.async {
                self.localURL = "No local asset found"
            }
        }
    }
}

#Preview {
    LocalPlayerView(song: SongModel())
}
