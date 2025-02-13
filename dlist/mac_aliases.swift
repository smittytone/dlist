//
//  aliases_mac.swift
//  dlist
//
//  Created by Tony Smith on 12/02/2025.
//

// /usr/sbin/system_profiler SPUSBDataType | grep "Serial Number" | cut -w -f 4


/*
 Get USB Serial Nuumber.
 Store alias, mapped to USBSN
 User specifies alias
    - get USBSN from alias
    - Check USBSN is present
        - Reject alias if not present
    - Get device name for USBSN device
    - Issue device name + path
 
 
so rather than
    minicom -D $(dlist)
 or
    minicom -D $(dlist 2)
 we have
    minicom -D $(dlist FART)
 
 look up FART in store for its USBSN
 no match?
    report error
 check connected devices' USBSNs
 if there is a match
    get the device's /dev/path
    write /dev/path to stdout
 else report error
 */




import Foundation
import SystemConfiguration

import IOKit
import IOKit.ps
import IOKit.usb
import IOKit.hid
import IOKit.serial


func findSerialDevices(_ deviceType: String, _ serialPortIterator: inout io_iterator_t ) -> kern_return_t {

    var result: kern_return_t = KERN_FAILURE
    if let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue) {
        let classesToMatchNSDict = classesToMatch as NSDictionary
        var classesToMatchDict = classesToMatchNSDict.swiftDictionary
        classesToMatchDict[kIOSerialBSDTypeKey] = deviceType
        let classesToMatchCFDictRef = (classesToMatchDict as NSDictionary) as CFDictionary
        result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatchCFDictRef, &serialPortIterator);
    }
    
    return result
}


func printSerialPaths(_ portIterator: io_iterator_t) {

    var serialService: io_object_t
    repeat {
        serialService = IOIteratorNext(portIterator)
        if serialService == 0 {
            break
        }
        
        let keya = "USB Serial Number"
                    
        let options : IOOptionBits = IOOptionBits(kIORegistryIterateParents) |
            IOOptionBits(kIORegistryIterateRecursively)
        
        if let sSerial : CFTypeRef = IORegistryEntrySearchCFProperty(serialService, kIOServicePlane, keya as CFString, nil, options) {
            print(String(describing: sSerial))
        }
        
        let key: CFString = kIOCalloutDeviceKey as CFString
        let bsdPathAsCFString: Any = IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0).takeUnretainedValue()
        let bsdPath = bsdPathAsCFString as? String
        if let path = bsdPath {
            //print(serialService.name() ?? "UNKNOWN")      // Useless
            print(path, serialService.id() ?? "UNKNOWN")          // Can we get anything useful from this???
        }
        
        IOObjectRelease(serialService)
    } while true
}


func getSerialDevices(_ portIterator: io_iterator_t) -> [String: String] {
    
    
    
    var deviceDict: [String: String] = [:]
    var serialService: io_object_t
    let serialKey = "USB Serial Number"
    repeat {
        serialService = IOIteratorNext(portIterator)
        if serialService == 0 {
            break
        }
        
        var serialNumber = "UNKNOWN"
        let searchOptions : IOOptionBits = IOOptionBits(kIORegistryIterateParents) | IOOptionBits(kIORegistryIterateRecursively)
        if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialService, kIOServicePlane, serialKey as CFString, nil, searchOptions) {
            serialNumber = String(describing: serialRef)
        }
        
        let key: CFString = kIOCalloutDeviceKey as CFString
        let bsdPathAsCFString: Any = IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0).takeUnretainedValue()
        let bsdPath = bsdPathAsCFString as? String
        if let path = bsdPath {
            if doKeepDevice(path) {
                deviceDict[path] = serialNumber
            }
        }
        
        IOObjectRelease(serialService)
    } while true
    
    return deviceDict
}


func doKeepDevice(_ path: String) -> Bool {
    
    let removals = ["cu.debug-console", "cu.Bluetooth-Incoming-Port"]
    for unwantedDevice in removals {
        if path.hasSuffix(unwantedDevice) {
            return false
        }
    }
    
    return true
}


func findMatchingPorts() -> [String: String] {
    
    var portIterator: io_iterator_t = 0
    let kernResult = findSerialDevices(kIOSerialBSDAllTypes, &portIterator)
    if kernResult == KERN_SUCCESS {
        defer { IOObjectRelease(portIterator) }
        return getSerialDevices(portIterator)
    }
    
    // Nothing found
    return [:]
}


extension io_object_t {
    
    func name() -> String? {
        
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate() }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }
    
    func id() -> UInt64? {
        
        let buf = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        if IORegistryEntryGetRegistryEntryID(self, buf) == KERN_SUCCESS {
            return buf.pointee
        }
        
        return nil
    }
}


/**
 NETWORK ONLY
struct USB {
    
    let interfaces = SCNetworkInterfaceCopyAll() as! [SCNetworkInterface]
    
    func getInterfaces() {
        for interface in interfaces {
            let bsdName = SCNetworkInterfaceGetBSDName(interface) as String? ?? "-"
            let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String? ?? "-"
            print("\(bsdName) -> \(displayName)")
        }
    }
}


func getInterfaces() {
    
    let usb = USB()
    usb.getInterfaces()
}
 */

extension NSDictionary {
    
    var swiftDictionary: Dictionary<String, Any> {
        var swiftDictionary = Dictionary<String, Any>()

        for key : Any in self.allKeys {
            let stringKey = key as! String
            if let keyValue = self.value(forKey: stringKey){
                swiftDictionary[stringKey] = keyValue
            }
        }

        return swiftDictionary
    }
}
