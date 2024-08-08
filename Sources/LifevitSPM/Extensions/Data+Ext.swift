//
//  File.swift
//  
//
//  Created by Marc on 8/8/24.
//

import Foundation

extension Data {
    var hexString: String? {
        return map { String(format: "%02x", $0) }.joined(separator: "")
    }
    
    var hexadecimal: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
