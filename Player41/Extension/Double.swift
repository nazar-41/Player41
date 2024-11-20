//
//  Double.swift
//  Player41
//
//  Created by Nazar Velkakayev on 09.11.2024.
//

import Foundation


extension Double {
    func toReadableTime() -> String {
        guard self.isFinite && !self.isNaN else {
            return "00:00"
        }
        
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Converts a Double in the range 0...1 to a percentage string.
    /// - Returns: A string representing the percentage, e.g., "13%"
    func toPercentageString() -> String {
        return String(format: "%.0f%%", self * 100)
    }
}
