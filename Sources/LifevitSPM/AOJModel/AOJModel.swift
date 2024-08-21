//
//  File.swift
//
//
//  Created by Marc on 8/8/24.
//

import Foundation


public struct AOJData {
    public var value: String?
    public var createdAt: Date?
    public var mode: AOJThermometerMode?
    public var deviceInfo: AOJDeviceInfo?
}

public struct AOJDeviceInfo {
    public var battery: String?
    public var version: String?
}


enum AOJCommands {
    enum Request {
        case LastMeasurement    // Request the last measurement data
        case SystemInfo         // Request system information data
        
        var toData: Data {
            
            let byte1: UInt8 = 0xAA
            let byte2: UInt8 = 0x01
            var command: UInt8 = 0x00
            let byte4: UInt8 = 0x00
            var control: UInt8 = 0x00
            
            switch self {
            case .LastMeasurement:
                command = 0xD1
                control = 0xD0
                
            case .SystemInfo:
                command = 0xD5
                control = 0xD4
            }
            
            return Data([byte1, byte2, command, byte4, control])
        }
    }
    
    enum Response: String {
        case LastMeasurement = "C1"     // Return the last measurement data
        case SystemInfo = "C5"          // Return system information data
        
        static func decode(str: String, forCommand command: Response) -> AOJData {
            if str.count == 16 {
                switch command {
                case .LastMeasurement:
                    let tempStart = str.index(str.startIndex, offsetBy: 8)
                    let tempEnd = str.index(str.startIndex, offsetBy: 12)
                    let subString = str[tempStart..<tempEnd]
                    let decimalValue = Double(UInt16(subString, radix: 16) ?? 0) / 100.0
                    let temperature = String(format: "%.1f", decimalValue)
                    
                    let modeStart = str.index(str.startIndex, offsetBy: 12)
                    let modeEnd = str.index(str.startIndex, offsetBy: 14)
                    let mode = AOJThermometerMode(rawValue: Int(str[modeStart..<modeEnd]) ?? 0) ?? .AdultForehead
                    
                    return AOJData(value: "\(temperature)", createdAt: Date(), mode: mode)
                    
                case .SystemInfo:
                    let batteryStart = str.index(str.startIndex, offsetBy: 10)
                    let batteryEnd = str.index(str.startIndex, offsetBy: 12)
                    let battery = str[batteryStart..<batteryEnd]
                    
                    let versionStart = str.index(str.startIndex, offsetBy: 12)
                    let versionEnd = str.index(str.startIndex, offsetBy: 14)
                    let version = str[versionStart..<versionEnd].map { String($0) }.joined(separator: ".")
                    
                    return AOJData(createdAt: Date(), deviceInfo: AOJDeviceInfo(battery: "\(battery)%", version: "v\(version)"))
                }
            } else {
                return AOJData()
            }
        }
    }
}


public enum AOJThermometerMode: Int {
    case AdultForehead = 1
    case ChildrenForehead = 2
    case Ear = 3
    case Object = 4
    
    var description: String {
        switch self {
        case .AdultForehead:
            "Adult Forehead"
        case .ChildrenForehead:
            "Children Forehead"
        case .Ear:
            "Ear"
        case .Object:
            "Object"
        }
    }
}

