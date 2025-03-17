//
//  BPMManager.swift
//
//
//  Created by Marc on 31/7/24.
//


import Foundation
import LSBluetoothPlugin

public protocol BPMDelegate {
    func onDeviceInfo(deviceInfo: LSDeviceInfo)
    func onStatusChanged(state: LSConnectState, description: String)
    func onDataReceived(data: LSBloodPressure)
    func onDeviceFound(deviceName: String)
}

public class BPMManager: NSObject {
    
    private let devicesAllowed = ["TMB-2284-B", "TMB-2296-BT", "TMB-2296-B"]
    public var delegate: BPMDelegate?
    
    public init(delegate: BPMDelegate? = nil) {
        self.delegate = delegate
    }
    
    public override init() {
        // log version
        let versionName : String?=LSBluetoothManager.default()?.versionName; print("version name:\(versionName ?? "default Name")");
        //init
        LSBluetoothManager.default()?.initManager(withDispatch: DispatchQueue.init(label: "bluetoothQueue"))
    }
    
    public func scanConnectAndRetrieveData() {
        //scan filter with device type
        let deviceTypes=[LSDeviceType.bloodGlucoseMeter.rawValue,
                         LSDeviceType.bloodPressureMeter.rawValue,
                         LSDeviceType.thermometer.rawValue]
        
        LSBluetoothManager.default()?.searchDevice(deviceTypes, results: { [weak self] (device) in
            guard let self = self else { return }
            
            guard let item = ScanResults(device: device) else { return }
            delegate?.onDeviceFound(deviceName: item.name ?? "unknown device name")
            if let name = item.name, self.devicesAllowed.contains(name) {
                //add target device
                let device = LSDeviceInfo()
                device.deviceName = name
                device.macAddress = item.macAddress ?? ""
                device.broadcastId = item.broadcastId
                device.manufacturerData = item.manufacturerData
                device.protocolType = item.protocolType
                device.preparePair = item.isPairMode
                device.deviceUserNumber = UInt.init(bitPattern: item.userNumber)
                device.deviceType = LSDeviceType(rawValue: LSDeviceType.RawValue((item.deviceType)))!
                device.isRegistered = (item.registerState == 0x01)
                device.delayDisconnect = true
                
                //stop search
                LSBluetoothManager.default()?.stopSearch();
                
                if(item.registerState == 0x01){
                    self.delegate?.onDeviceInfo(deviceInfo: device)
                    
                    LSBluetoothManager.default()?.addDevice(device)
                    LSBluetoothManager.default()?.startDeviceSync(self)
                }
                else{
                    //set the system pairing confirmation pop-up prompt
                    device.systemPairConfirm = true;
                    //pair device
                    LSBluetoothManager.default()?.pairDevice(device, delegate: self);
                }
            }
        })
    }
    
    
    public func connectAndRetrieveData(for device: LSDeviceInfo) {
        self.delegate?.onDeviceInfo(deviceInfo: device)
        
        LSBluetoothManager.default().stopSearch()
        LSBluetoothManager.default()?.setDevices([])
        LSBluetoothManager.default()?.addDevice(device)
        LSBluetoothManager.default()?.startDeviceSync(self)
    }
    
    
    public func connectAndRetrieveData(withMacAddress macAddress: String) {
        let device = LSDeviceInfo()
        device.macAddress = macAddress
        device.broadcastId = macAddress.replacingOccurrences(of: ":", with: "")
        device.deviceType = .bloodPressureMeter
        device.delayDisconnect = true
        
        self.delegate?.onDeviceInfo(deviceInfo: device)
        LSBluetoothManager.default().stopSearch()
        LSBluetoothManager.default()?.setDevices([])
        LSBluetoothManager.default()?.addDevice(device)
        LSBluetoothManager.default()?.startDeviceSync(self)
    }
}

extension BPMManager: LSDevicePairingDelegate {
    public func bleDevice(_ device: LSDeviceInfo!, didPairStateChanged state: LSPairState) {
        guard let lsBluetoothManager = LSBluetoothManager.default() else { return }
        guard let delegate = self.delegate else { return }
        
        device.delayDisconnect = true
        lsBluetoothManager.addDevice(device)
        lsBluetoothManager.startDeviceSync(self)
        
        delegate.onDeviceInfo(deviceInfo: device)
    }
}

extension BPMManager: LSDeviceDataDelegate {
    public func bleDevice(_ device: LSDeviceInfo!, didConnectStateChanged state: LSConnectState) {
        switch state {
        case .unknown:
            print("")
            
        case .connected:
            print(">> CONNECTED ✅")
            delegate?.onStatusChanged(state: state, description: "CONNECTED")
            
        case .failure:
            print(">> FAILURE ❌")
            delegate?.onStatusChanged(state: state, description: "FAILURE")
            LSBluetoothManager.default().stopSearch()
            LSBluetoothManager.default().stopDeviceSync()
            
        case .disconnect:
            print(">> DISCONNECTED")
            delegate?.onStatusChanged(state: state, description: "DISCONNECTED")
            LSBluetoothManager.default().stopDeviceSync()
            
        case .connecting:
            print(">> CONNECTING...")
            delegate?.onStatusChanged(state: state, description: "CONNECTING...")
            
        case .timeout:
            print(">> TIMEOUT ⚠️")
            delegate?.onStatusChanged(state: state, description: "TIMEOUT")
            LSBluetoothManager.default().stopSearch()
            LSBluetoothManager.default().stopDeviceSync()
            
        case .success:
            print(">> SUCCESS")
            delegate?.onStatusChanged(state: state, description: "SUCCESS")
            LSBluetoothManager.default().stopSearch()
            
        @unknown default:
            print("")
        }
    }
    
    
    public func bleDevice(_ device: LSDeviceInfo!, didDataUpdateForBloodPressureMonitor data: LSBloodPressure!) {
        delegate?.onDataReceived(data: data)
    }
}
