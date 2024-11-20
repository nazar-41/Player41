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
    
    init(song: SongModel) {
        self.song = song
        self._vm = .init(wrappedValue: .init(song: song))
    }
    
    var body: some View {
        VStack {
            if let asset = song.asset{
                let downloadState = vm.downloadState[asset.stream.id]
                VStack {
                    HStack{
                        if downloadState == .notDownloaded {
                            Button("Download"){
                                vm.downloadAsset(asset)
                            }
                        }
                        if downloadState == .downloading {
                            Text(vm.downloadProgress[asset.stream.id]?.toPercentageString() ?? "0%")
                            Button("Cancel"){
                                    vm.cancelDownload(asset)
                            }
                        }
                        
                        if downloadState == .downloaded {
                            Button("Delete"){
                                vm.deleteAsset(asset)
                            }
                        }
                    }
                }
                .contentShape(.rect)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    DownloadBtnView(song: .init())
}
