//
//  KelvinManager.swift
//
//
//  Created by Marc on 8/8/24.
//

import UIKit
import CoreBluetooth


public protocol KelvinDelegate {
    func onConnectedPeripheral(identifier: String, name: String)
    func onDeviceInfo(deviceInfo: KelvinDeviceInfo)
    func onDataReceived(data: KelvinData)
}


public class KelvinManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    public var delegate: KelvinDelegate?
    private let devicesAllowed = ["AOJ-20F"]

    private var centralManager: CBCentralManager? = nil
    private var discoveredPeripheral: CBPeripheral? = nil
    private var characteristicsList: [CBCharacteristic] = []
    
    
    public init(delegate: KelvinDelegate? = nil) {
        self.delegate = delegate
    }
    
    
    public func scanConnectAndRetrieveData() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func disconnect(_ peripheral: CBPeripheral? = nil) {
        if let peripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            centralManager = nil
        } else {
            guard let discoveredPeripheral else { return }
            centralManager?.cancelPeripheralConnection(discoveredPeripheral)
            centralManager = nil
        }
    }
    
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
            break
            
        @unknown default:
            break
        }
    }
    
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let peripheralName = peripheral.name else { return }
        if self.devicesAllowed.contains(peripheralName) {
            discoveredPeripheral = peripheral
            delegate?.onConnectedPeripheral(identifier: peripheral.identifier.uuidString, name: peripheralName)
            
            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager?.stopScan()
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                characteristicsList.append(characteristic)
                
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
                
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let strValue = characteristic.value?.hexString?.uppercased(), !strValue.isEmpty {
            
            if strValue == "00" {
                // Ask for SystemData
                guard let char = characteristicsList.first(where: { $0.uuid == CBUUID(string: "FFE2") }) else { return }
                discoveredPeripheral?.writeValue(KelvinCommands.Request.SystemInfo.toData, for: char, type: .withResponse)
            } else {
                let data = KelvinCommands.Response.decode(str: strValue, forCommand: strValue.toResponseCommand)
                
                if let deviceInfo = data.deviceInfo {
                    delegate?.onDeviceInfo(deviceInfo: deviceInfo)
                } else {
                    delegate?.onDataReceived(data: data)
                }
            }
        }
    }
}

extension KelvinManager {
    public func retrieveLastMeasure() {
        guard let char = characteristicsList.first(where: { $0.uuid == CBUUID(string: "FFE2") }) else { return }
        discoveredPeripheral?.writeValue(KelvinCommands.Request.LastMeasurement.toData, for: char, type: .withResponse)
    }
    
    public func retrieveDeviceInfo() {
        guard let char = characteristicsList.first(where: { $0.uuid == CBUUID(string: "FFE2") }) else { return }
        discoveredPeripheral?.writeValue(KelvinCommands.Request.SystemInfo.toData, for: char, type: .withResponse)
    }
}
