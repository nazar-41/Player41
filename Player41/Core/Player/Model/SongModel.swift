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
            id: id
        )
    }
    
    var isDownloaded: Bool {
           return AssetPersistenceManager.sharedManager.localAssetForStream(with: id) != nil
    }
    
    var localURL: URL? {
        guard let localAsset = AssetPersistenceManager.sharedManager.localAssetForStream(with: id) else {
            return nil
        }
        return localAsset.urlAsset.url
    }
}
