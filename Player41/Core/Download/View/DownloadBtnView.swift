//
//  DownloadBtnView.swift
//  Dinle
//
//  Created by Nazar Velkakayev on 22.07.2024.
//

import SwiftUI

struct DownloadBtnView: View {
    let song: SongModel
    @StateObject private var vm: VM_DownloadBtnView
    
    @State private var showDeleteConfirmation = false
    
    init(song: SongModel) {
        self.song = song
        self._vm = .init(wrappedValue: .init(song: song))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let asset = song.asset {
                let downloadState = vm.downloadState[asset.stream.id]
                
                VStack(spacing: 16) {
                    HStack {
                        // Download Button
                        if downloadState == .notDownloaded {
                            Button(action: {
                                vm.downloadAsset(asset)
                            }) {
                                Label("Download", systemImage: "arrow.down.circle.fill")
                                    .font(.body)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        
                        // Downloading Progress
                        if downloadState == .downloading {
                            VStack {
                                ProgressView(value: vm.downloadProgress[asset.stream.id] ?? 0, total: 1)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(height: 6)
                                    .padding(.vertical, 8)
                                
                                Text(vm.downloadProgress[asset.stream.id]?.toPercentageString() ?? "0%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    vm.cancelDownload(asset)
                                }) {
                                    Label("Cancel", systemImage: "xmark.circle.fill")
                                        .font(.body)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        // Downloaded Button with Delete Confirmation
                        if downloadState == .downloaded {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash.fill")
                                    .font(.body)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .alert(isPresented: $showDeleteConfirmation) {
                                Alert(
                                    title: Text("Delete Download"),
                                    message: Text("Are you sure you want to delete this asset?"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        vm.deleteAsset(asset)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
    }
}



#Preview {
    DownloadBtnView(song: .init())
}
