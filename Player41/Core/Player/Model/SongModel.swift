//
//  SongModel.swift
//  Player41
//
//  Created by Nazar Velkakayev on 20.11.2024.
//

import Foundation
import AVFoundation


struct SongModel{
    let id: String = "abcd"
    let urlString: String = "http://cdnbakmi.kaltura.com/p/243342/sp/24334200/playManifest/entryId/0_uka1msg4/flavorIds/1_vqhfu6uy,1_80sohj7p/format/applehttp/protocol/http/a.m3u8"
    
    var url: URL?{
        return URL(string: urlString)
    }
    
    var asset: Asset?{
        guard let url = url else{return nil}
        return .init(urlAsset: .init(url: url), stream: .init(id: id, playlistURL: url.absoluteString), id: id)
    }
    
    var player: AVPlayer?{
        guard let url = url else{return nil}

        return .init(url: url)
    }
}
