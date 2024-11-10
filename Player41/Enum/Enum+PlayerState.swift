//
//  Enum+PlayerState.swift
//  Player41
//
//  Created by Nazar Velkakayev on 09.11.2024.
//

import Foundation

enum Enum_PlayerState{
    case playing
    case paused
    case loading
    case error(String)
    
    var title: String{
        switch self {
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .loading:
            return "Loading..."
        case .error(let error):
            return "Error: \(error)"
        }
    }
}
