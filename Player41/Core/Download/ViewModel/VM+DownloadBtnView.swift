//
//  VM+DownloadBtnView.swift
//  Dinle
//
//  Created by Nazar Velkakayev on 22.07.2024.
//

import Foundation
import Combine

class VM_DownloadBtnView: ObservableObject {
    @Published var song: SongModel
    @Published var showDeleteAlert: Bool = false
    
    @Published var downloadProgress: [String : Double] = [:]
    @Published var downloadState: [String : Asset.DownloadState] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init(song: SongModel) {
        self.song = song
        NotificationCenter.default.publisher(for: .AssetDownloadProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let userInfo = notification.userInfo,
                   let name = userInfo[Asset.Keys.id] as? String,
                   let percentDownloaded = userInfo[Asset.Keys.percentDownloaded] as? Double {
                    self.downloadProgress[name] = percentDownloaded
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .AssetDownloadStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let userInfo = notification.userInfo,
                   let name = userInfo[Asset.Keys.id] as? String,
                   let rawState = userInfo[Asset.Keys.downloadState] as? String,
                   let state = Asset.DownloadState(rawValue: rawState) {
                    self.downloadState[name] = state
                }
            }
            .store(in: &cancellables)
        
        self.setState()

    }
    
    func downloadAsset(_ asset: Asset) {
        AssetPersistenceManager.sharedManager.downloadStream(for: asset)
    }
    
    func deleteAsset(_ asset: Asset) {
        AssetPersistenceManager.sharedManager.deleteAsset(asset)
        self.downloadState[asset.stream.id] = .notDownloaded
    }
    
    func cancelDownload(_ asset: Asset) {
        AssetPersistenceManager.sharedManager.cancelDownload(for: asset)
        downloadState[asset.stream.id] = .notDownloaded
    }
    
    private func setState() {
        guard let asset = song.asset else {return}
        downloadState[asset.stream.id] = AssetPersistenceManager.sharedManager.downloadState(for: asset)
    }
    
//    func clickAction(){
//        guard let asset = song.asset else{return}
//#if !targetEnvironment(simulator)
//        switch downloadState[asset.stream.id] {
//        case .notDownloaded:
//            downloadAsset(asset)
//        case .downloading:
//            cancelDownload(asset)
//        case .downloaded:
//            showDeleteAlert = true
//        case .none:
//            downloadAsset(asset)
//        }
//#endif
//    }
}
