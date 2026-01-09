/*
    dlist
    linux_aliases.swift

    Copyright © 2026 Tony Smith. All rights reserved.

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

#if os(Linux)
import Foundation
import Clibudev


/**
 Use udev to get a USB-connected serial adaptor's USB Serial Number.

 - Note Code derived from 
    `http://cholla.mmto.org/computers/usb/OLD/tutorial_usbloger.html` and
    `https://github.com/robertalks/udev-examples/blob/master/udev_example1.c`

 - Parameters
    - device: The device name, eg. `ttyUSB0`.

 - Returns The device's serial number, or `nil` on error.
 
func getSerialNumber(_ device: String) -> String? {

    // Get the `/sys` path to the specified device
    let devicePath = SYS_PATH_LINUX + device

    // udev access must begin with `udev_new()` (see `man udev`)
    // and, if we get a pointer to the struct, we have to free it
    // before the function exits
    guard let udev = udev_new() else { return nil }
    defer { udev_unref(udev) }
    
    // Get the udev representation of the specified device.
    // Again, make sure we free it before the function exits
    guard var dev = udev_device_new_from_syspath(udev, devicePath) else { return nil }
    defer { udev_device_unref(dev) }

    // Get the device's parent node
    dev = udev_device_get_parent_with_subsystem_devtype(dev, "usb", "usb_device")
    let serial = udev_device_get_sysattr_value(dev, "serial")!
    // For some reason the following yields 'cannot find 'free' in scope' in Swift 6
    // defer { free(serial) }

    return String(cString: serial)
}
 */


/**
 Use udev to get a USB-connected serial adaptor's USB Serial Number
 and other data.

 - Parameters
    - device: The device name, eg. `ttyUSB0`.

 - Returns The device's data, or an unpopulated struct on error.
 */
func getDeviceInfo(_ device: String) -> SerialDeviceInfo {

    var serialDeviceInfo = SerialDeviceInfo()

    // Get the `/sys` path to the specified device
    let devicePath = SYS_PATH_LINUX + device

    // udev access must begin with `udev_new()` (see `man udev`)
    // and, if we get a pointer to the struct, we have to free it
    // before the function exits
    guard let udev = udev_new() else { return serialDeviceInfo }
    defer { udev_unref(udev) }
    
    // Get the udev representation of the specified device.
    // Again, make sure we free it before the function exits
    guard var dev = udev_device_new_from_syspath(udev, devicePath) else { return serialDeviceInfo }
    defer { udev_device_unref(dev) }

    // Get the device's parent node and then its USB serial number
    dev = udev_device_get_parent_with_subsystem_devtype(dev, "usb", "usb_device")
    if let value = udev_device_get_sysattr_value(dev, "serial") {
        serialDeviceInfo.serialNumber = String(cString: value)
    }

    // Get the device's product data
    if let value = udev_device_get_sysattr_value(dev, "product") {
        serialDeviceInfo.productType = String(cString: value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Get the device's vendor name. If that fails, try for the ID
    if let value = udev_device_get_sysattr_value(dev, "manufacturer") {
        serialDeviceInfo.vendorName = String(cString: value).trimmingCharacters(in: .whitespacesAndNewlines)
    } else if let value = udev_device_get_sysattr_value(dev, "idVendor") {
        serialDeviceInfo.vendorName = "0x" + String(cString: value).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    return serialDeviceInfo
}


/*
func apply(alias: String, to serial: String, path: String = "") -> Bool {

    // TODO Update deviceLine for ttyACMx devices too
    let deviceLine = "KERNEL==\"ttyUSB?\", ATTRS{serial}==\"\(serial)\", SYMLINK+=\"\(alias)\", MODE=\"0666\"\n"
    let fm = FileManager.default
    if fm.fileExists(atPath: UDEV_RULES_PATH_LINUX) {
        do {
            var rulesFileText = try String(contentsOfFile: UDEV_RULES_PATH_LINUX)
            
            // Make sure the alias is not in use
            if rulesFileText.contains("SYMLINK+=\"\(alias)\"") {
                reportErrorAndExit("Alias \(alias) already in use", 3)
            }
            
            // Check the serial number
            // If it already exists, update its alias
            if let matchSerial = rulesFileText.firstMatch(of: #/ATTRS{serial}=="(.*?)"/#) {
                let oldSerial = String(matchSerial.1) 
                
                if let matchAlias = rulesFileText.firstMatch(of: #/SYMLINK\+="(.*?)"/#) {
                    let oldAlias = String(matchAlias.1) 
                    if oldAlias != alias {
                        rulesFileText = rulesFileText.replacingOccurrences(of: "+=\"\(oldAlias)", with: "+=\"\(alias)")
                        reportInfo("Alias changed from \(oldAlias) to \(alias) -- reconnect your device to make use of it")
                    }
                }
            } else {
                rulesFileText += deviceLine
            }
            
            return writeRules(rulesFileText)
        } catch {
            // Fallthrough
        }
    } else {
        return writeRules(deviceLine)
    }

    return false
}


func writeRules(_ fileContents: String) -> Bool {
    
    do {
        try fileContents.write(toFile: UDEV_RULES_PATH_LINUX, atomically: false, encoding: .utf8)
        return true
    } catch {
        // Fallthrough
        print("WRITE FAIL")
    }
    
    return false
}
*/
#endif
