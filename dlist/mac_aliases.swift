/*
    dlist
    mac_aliases.swift

    Copyright © 2025 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/


import Foundation
import IOKit
// Extra imports required to access certain constants
import IOKit.serial
import IOKit.usb


/**
 Scan the IO registry for serial port devices.
 
 - Returns A dictionary of device data keyed by device path, or an empty dictionary.
 */
func findConnectedSerialDevices() -> [String: SerialDeviceInfo] {
    
    var portIterator: io_iterator_t = 0
    
    if let matchesCFDict = IOServiceMatching(kIOSerialBSDServiceValue) {
        // Convert received CFDictionary to a Swift equivalent so
        // we can easily punch in the values we want...
        let matchesNSDict = matchesCFDict as NSDictionary
        var matches = matchesNSDict.swiftDictionary
        matches[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes
        
        // ...and convert it back again for use
        let matchesCFDictRef = (matches as NSDictionary) as CFDictionary
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchesCFDictRef, &portIterator) == KERN_SUCCESS {
            // We got a port iterator back - ie. one or more matching devcies - so use it
            defer { IOObjectRelease(portIterator) }
            return getSerialDevices(portIterator)
        }
    }
    
    // No devices found, or error
    return [:]
}


/**
 Given a collection of serial devices, obtained via an iterator, get each
 one's device file path and its unique USB serial number.
 
 - Parameters
    - portIterator: An IOKit iterator for walking a list of devices.
 
 - Returns A dictionary of device data keyed by device path, or an empty dictionary.
 */
func getSerialDevices(_ portIterator: io_iterator_t) -> [String: SerialDeviceInfo] {
    
    var serialDevices: [String: SerialDeviceInfo] = [:]
    var serialDevice: io_service_t
    
    repeat {
        serialDevice = IOIteratorNext(portIterator)
        if serialDevice == 0 {
            break
        }
        
        // Get the Unix device path
        // Only if we have this do we continue to get the other device data points
        let devicePathAsCFString: CFTypeRef? = IORegistryEntryCreateCFProperty(serialDevice, kIOCalloutDeviceKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue()
        if let devicePath = devicePathAsCFString as? String {
            // Make sure we don't include cu.Bluetooth etc
            if doKeepDevice(devicePath) {
                var serialDeviceInfo = SerialDeviceInfo()
                let searchOptions : IOOptionBits = IOOptionBits(kIORegistryIterateParents) | IOOptionBits(kIORegistryIterateRecursively)
                
                // Try to get the device's USB serial number
                if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialDevice, kIOServicePlane, "USB Serial Number" as CFString, nil, searchOptions) {
                    serialDeviceInfo.serialNumber = String(describing: serialRef)
                }
                
                // Try to get the device's product type
                if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialDevice, kIOServicePlane, kUSBProductString as CFString, nil, searchOptions) {
                    serialDeviceInfo.productType = String(describing: serialRef).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Try to get the device's vendor. Go for the name, but if that fails fall back to the ID
                if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialDevice, kIOServicePlane, kUSBVendorString as CFString, nil, searchOptions) {
                    serialDeviceInfo.vendorName = String(describing: serialRef).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialDevice, kIOServicePlane, kUSBVendorID as CFString, nil, searchOptions) {
                    serialDeviceInfo.vendorName = "0x" + String(describing: serialRef).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                serialDevices[devicePath] = serialDeviceInfo
            }
        }
        
        // Release the current device object
        IOObjectRelease(serialDevice)
    } while true
    
    // Return the list of devices and serial numbers
    return serialDevices
}


/**
 Compare a discovered device for the standard ones macOS adds and which we
 are not interested in.
 
 - Parameter
    - path: The device's Unix file path.
 
 - Returns `true` if the device is good to use, otherwise `false`.
 */
func doKeepDevice(_ path: String) -> Bool {
    
    for unwantedDevice in ignorableDevices {
        if path.contains(unwantedDevice) {
            return false
        }
    }
    
    return true
}


/**
 Make a list of serial devices we can ignore. Some are added by macOS, others by users,
 eg. `cu.myAirPodsMax`. These can be added to the file `${HOME}/.config/dlist/ignorables`
 on a one-per-line basis. 

 - Returns An array of device names to ignore.
 */
func getIgnorables() -> [String] {
    
    let knownIgnorables = ["cu.debug-console", "cu.Bluetooth-Incoming-Port"]
    
    let fm = FileManager.default
    let ignoresFileURL = fm.homeDirectoryForCurrentUser.appendingPathComponent(".config/dlist/ignorables")
    let ignoresFilePath = ignoresFileURL.path
    if fm.fileExists(atPath: ignoresFilePath) {
        if let ignores = try? String.init(contentsOfFile: ignoresFilePath, encoding: .utf8) {
            let parts = ignores.split(separator: "\n")
            if !parts.isEmpty {
                var userIgnorables: [String] = []
                for part in parts {
                    // FROM 0.2.1
                    // Remove the `/dev/` from the ignorable name, if it's included
                    if part.hasPrefix("/dev/") {
                        let deviceNameIndex = part.index(part.startIndex, offsetBy: 5)
                        let deviceName = part[deviceNameIndex..<part.endIndex]
                        userIgnorables.append(String(deviceName))
                    } else {
                        userIgnorables.append(String(part))
                    }
                }
                
                return userIgnorables + knownIgnorables
            }
        }
    }
    
    return knownIgnorables
}
