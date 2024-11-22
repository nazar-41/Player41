//
//  SongModel.swift
//  Player41
//
//  Created by Nazar Velkakayev on 20.11.2024.
//

import Foundation
import AVFoundation


struct SongModel {
    let id: String = "abcd"
    let urlString: String = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
    
    var url: URL? {
        URL(string: urlString)
    }
    
    var asset: Asset? {
        guard let url else { return nil }
        return Asset(
            urlAsset: AVURLAsset(url: url),
            stream: Stream(id: id, playlistURL: url.absoluteString),
            id: id
        )
    }
    
    var isDownloaded: Bool {
           guard let stream = asset?.stream else { return false }
           return AssetPersistenceManager.sharedManager.localAssetForStream(with: stream) != nil
    }
    
    var localURL: URL? {
        guard let stream = asset?.stream,
              let localAsset = AssetPersistenceManager.sharedManager.localAssetForStream(with: stream) else {
            return nil
        }
        return localAsset.urlAsset.url
    }
}
