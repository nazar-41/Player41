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
    
    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear{
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
        guard let localURL = song.localURL else{return}
        player = .init(url: localURL)
    }
}

#Preview {
    LocalPlayerView(song: SongModel())
}
