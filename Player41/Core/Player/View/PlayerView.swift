//
//  PlayerView.swift
//  Player41
//
//  Created by Nazar Velkakayev on 09.11.2024.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    @StateObject private var vm = VM_PlayerView()
    
    var body: some View {
        VStack(spacing: 24) {
            

            // Video Player
            VideoPlayer(player: vm.song.player)
                .aspectRatio(16 / 9, contentMode: .fit)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
            
            // Playback Status
            Text(vm.playerStatus.title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            
            // Playback Controls
            HStack {
                Spacer()
                
                Button {
                    vm.play()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                
                Button {
                    vm.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            
            // Time Slider
            VStack {
                HStack {
                    Text(vm.currentTime.toReadableTime())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(vm.totalDuration.toReadableTime())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $vm.currentTime,
                    in: 0...(vm.totalDuration > 0 ? vm.totalDuration : 1),
                    onEditingChanged: { isDragging in
                        if isDragging {
                            vm.pause()
                        } else {
                            vm.seek(to: vm.currentTime)
                            vm.play()
                        }
                    }
                )
                .accentColor(.blue)
            }
            
            // Buffer Progress
            VStack(alignment: .leading) {
                Text("Buffered: \(Double(vm.bufferProgress * vm.totalDuration).toReadableTime()) (\(Int(vm.bufferProgress * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Download
            DownloadBtnView(song: vm.song)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PlayerView()
}
