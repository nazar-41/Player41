//
//  Asset.swift
//  Dinle
//
//  Created by Nazar Velkakayev on 22.11.2024.
//

import Foundation
import AVFoundation

struct Asset: Equatable, Identifiable{
    var urlAsset: AVURLAsset
    let id: String
}

extension Asset {
    enum DownloadState: String {
        case notDownloaded
        case downloading
        case downloaded
    }
}


extension Asset {
    struct Keys {
        static let id = "AssetIdKey"
        static let percentDownloaded = "AssetPercentDownloadedKey"
        static let downloadState = "AssetDownloadStateKey"
        static let downloadSelectionDisplayName = "AssetDownloadSelectionDisplayNameKey"
    }
}
