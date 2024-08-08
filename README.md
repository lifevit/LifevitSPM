# LifevitSDK on Swift Package Manager

## Requirements

- Requires Xcode 15.X or above
- For Objective C projects add `-ObjC` on `Other Linker Flags` option.




## Installation


### Installing from Xcode

* Add a package by selecting `File` → `Add Packages…` in Xcode’s menu bar.


* Search for the LifevitSDK using the repo's URL:
```
https://github.com/lifevit/LifevitSPM.git
```

* Set the **Dependency Rule** to be `branch` `main` and then, select **Add Package**.

* Add into `Info.plist`: **Privacy - Bluetooth Always Usage Description** something like:

 
	>This allows you to connect with your BLE devices via Bluetooth.



## Usage
### 1. For Lifevit Devices
You'll need to import:
`import LifevitSDK`

You have a complete documentation of the library and all its devices in:

[https://developers.lifevit.es/](https://developers.lifevit.es/)


### 2. For Transtek Devices (TMB-2284-B, TMB-2296-BT)

You'll need to import:

```
import LifevitSPM
import LSBluetoothPlugin
```

1- On your ViewController:

```
class MyViewController {

let transtekManager = TranstekManager()
var transtekDevice: LSDeviceInfo? // If you want to save device info
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transtekManager.delegate = self
    }
}

```

2- You can call this methods to connect and retrieve data:

```
// Main func to connect and receive data:
transtekManager.scanConnectAndRetrieveData()

// More options to connect and receive data
transtekManager.connectAndRetrieveData(withMacAddress: "B8:B7:7D:0E:63:16") // <- Change this fake mac
transtekManager.connectAndRetrieveData(for: transtekDevice)
```


3- You'll receive device data on TranstekDelegate

```
extension MyViewController: TranstekDelegate {
    func onDeviceInfo(deviceInfo: LSDeviceInfo) {
        // Callback with connected device info
        transtekDevice = deviceInfo
    }
    
    func onStatusChanged(state: LSConnectState, description: String) {
        // Callback with live connection state
    }
    
    func onDataReceived(data: LSBloodPressure) {
        // Callback with Data received
    }
}
```


-


### ⚠️ Attention

>- If you’re having trouble connecting your Transtek device, try putting into pairing mode by pressing and holding the button. Once it’s paired, you won’t need to do this again. 


### 3. For AOJ Thermometer (AOJ-20F)
You'll need to import:

```
import LifevitSPM
```

1- On your ViewController:

```
class MyViewController {

let manager = AOJManager()
var deviceData: AOJData? // If you want to save device info
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
    }
}

```

2- You can call this method to connect and retrieve data:

```
manager.scanConnectAndRetrieveData()
```

3- You'll receive live device data on AOJDelegate

```
extension MyViewController: AOJDelegate {
	func onDeviceInfo(deviceInfo: AOJDeviceInfo) {
        // Callback with connected device info
    }
    
    func onDataReceived(data: AOJData) {
        // Callback with Data received
        self.deviceData = data
    }
}
```




## Example Demo App

You can easily download the DemoApp, which integrates the LifevitSDK, through the Swift Package Manager (SPM). This allows you to explore and experiment with the SDK's features directly within the app.

[Download Example App](https://github.com/lifevit/ios-app/tree/3.0.0).


## Questions and Issues

Please provide any feedback via a [GitHub
Issue](https://github.com/lifevit/LifevitSPM/issues).
