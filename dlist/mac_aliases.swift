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
import IOKit
import IOKit.ps
import IOKit.usb
import IOKit.hid
import IOKit.serial


/**
 Scan the IO registry for serial port devices.
 
 - Returns A dictionary of device paths and their serial numbers, or a empty dictionary.
 */
func findConnectedSerialDevices() -> [String: String] {
    
    var portIterator: io_iterator_t = 0
    
    if let matchesCFDict = IOServiceMatching(kIOSerialBSDServiceValue) {
        // Convert recieved CFDictionary to a Swift equivalent so
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
 
 - Returns A dictionary of device paths and their serial numbers, or a empty dictionary.
 */
func getSerialDevices(_ portIterator: io_iterator_t) -> [String: String] {
    
    var serialDevices: [String: String] = [:]
    var serialDevice: io_service_t
    let serialKey = "USB Serial Number"
    let bsdPathKey = kIOCalloutDeviceKey
    
    repeat {
        serialDevice = IOIteratorNext(portIterator)
        if serialDevice == 0 {
            break
        }
        
        var serialNumber = "UNKNOWN"
        let searchOptions : IOOptionBits = IOOptionBits(kIORegistryIterateParents) | IOOptionBits(kIORegistryIterateRecursively)
        if let serialRef : CFTypeRef = IORegistryEntrySearchCFProperty(serialDevice, kIOServicePlane, serialKey as CFString, nil, searchOptions) {
            // Got a serial number - convert to text
            serialNumber = String(describing: serialRef)
        }
        
        // Get the Unix device path
        let bsdPathAsCFString: CFTypeRef? = IORegistryEntryCreateCFProperty(serialDevice, bsdPathKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue()
        if let bsdPath = bsdPathAsCFString as? String {
            if doKeepDevice(bsdPath) {
                serialDevices[bsdPath] = serialNumber
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
    
    let removals = ["cu.debug-console", "cu.Bluetooth-Incoming-Port"]
    for unwantedDevice in removals {
        if path.contains(unwantedDevice) {
            return false
        }
    }
    
    return true
}
