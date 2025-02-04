/*
    dlist
    main.swift

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


// MARK: - Constants

let DEVICE_PATH = "/dev/"


// MARK: - Global Variables

// CLI argument management
var argIsAValue: Bool   = false
var argType: Int        = -1
var argCount: Int       = 0
var prevArg: String     = ""


// MARK: - Functions

/**
    Get a list of possible devices from the `/dev` directory.
    At this point we don't parse the list: we just obtain it, but
    we only include those devices prefixed `cu.`.
 
    - Returns An array of the items in `/dev`.
 */
private func getDevices(from devicesPath: String) -> [String] {
    
    var list: [String] = []
    var finalList: [String] = []
    let fm = FileManager.default
    
    do {
        list = try fm.contentsOfDirectory(atPath: devicesPath)
    } catch {
        reportErrorAndExit("\(devicesPath) cannot be found", 2)
    }
    
    for device in list {
        if device.hasPrefix("cu.") {
            finalList.append(device)
        }
    }

    return finalList
}


/**
    Get a list of possible devices from the `/dev` directory.
    At this point we don't parse the list: we just obtain it.
 
    - Parameters
        - devices: An array of `cu.*` entries from `/dev`.
 
    - Returns An array containing only the devices we're interested in,
              ie. connected MCU boards.
 */
private func pruneDevices(_ devices: [String]) -> [String] {
    
    guard devices.count > 0 else { return devices }
    
    // This is the list of known `cu.` devices that are definitely not MCUs
    let removals = ["cu.debug-console", "cu.Bluetooth-Incoming-Port"]
    
    var prunedDevices: [String] = []
    for device in devices {
        if removals.contains(device) {
            continue
        }
        
        prunedDevices.append(device)
    }
    
    
    return prunedDevices
}


/**
    List any and all available connected MCUs.
    
    If only one is available, write its path to STDOUT for piping.
    
    If multiple are available, write their paths as a table to STDERR so the user
    can select one of them by calling `dlist` with its index as an argument.
    
    If a selected device is available, write is path to STDOUT for piping.
 
    If no devices are present, write a warning to STDERR.
 
    - Parameters
        - targetDevice: The index of a specified device on a dlist-generated list.
 */
private func showDevices(_ targetDevice: Int) {
    
    let baseList = getDevices(from: DEVICE_PATH)
    let shortList = pruneDevices(baseList)

    if shortList.count > 0 {
        if shortList.count == 1 {
            // Warn if a device has been specified anyway
            if targetDevice != -1 && targetDevice != 1 {
                reportWarning("\(targetDevice) is out of range (1)")
            }
            
            // Write the path of the only device to STDOUT
            writeToStdout(DEVICE_PATH + shortList[0])
        } else {
            if targetDevice >= shortList.count {
                reportWarning("\(targetDevice) is out of range (1-\(shortList.count))")
            }
            var count = 1
            for device in shortList {
                if targetDevice != -1 && count == targetDevice {
                    // Write the path of the chosen device to STDOUT
                    writeToStdout(DEVICE_PATH + device)
                } else {
                    // List devices to STDERR (ie. for humans)
                    let output = String(format: "%d. ", count)
                    reportInfo(output + device)
                }
                
                count += 1
            }
        }
    } else {
        reportWarning("No connected devices")
    }
}


/**
    Display help
 */
private func showHelp() {

    reportInfo("List connected USB-to-serial adaptors\n")
    reportInfo("Usage:")
    reportInfo("  dlist [--help] [device index]\n")
    reportInfo("Call dlist to view or use a connected adaptor's device path.")
    reportInfo("If multiple adaptors are connected, dlist will list them. In")
    reportInfo("this case, to use one of them, call dlist with the requiired")
    reportInfo("adaptor's index in the list.\n")
    reportInfo("Examples:")
    reportInfo("  One device connected:  minicom -d $(dlist) -b 9600")
    reportInfo("  Two devices connected, use number 1: minicom -d $(dlist 1) -b 9600\n")
}
  

// MARK: - Runtime Start

// Look for help
for arg in CommandLine.arguments {
    // Look for compound flags, ie. a single dash followed by
    // more than one flag identifier
    if arg.lowercased() == "-h" || arg.lowercased() == "--help" {
        showHelp()
        exit(EXIT_SUCCESS)
    }
}

// Set up Ctrl-C trap
configureSignalHandling()

// Process the (separated) arguments
var targetDevice = -1
for argument in CommandLine.arguments {
    // Ignore the first comand line argument
    if argCount == 0 {
        argCount += 1
        continue
    }
    
    // Check for negative numbers
    if argument.hasPrefix("-") {
        reportErrorAndExit("Device reference \(argument) is invalid (negative integer)")
    }
    
    // Get the device choice and conver string arg to int
    if let deviceChoice = Int(argument) {
        // Make sure zero was not provided
        if deviceChoice == 0 {
            reportErrorAndExit("Device reference \(argument) is invalid (zero)")
        }
        
        targetDevice = deviceChoice
    } else {
        reportErrorAndExit("Device reference is not an integer. List available devices to get this value.")
    }

    argCount += 1
}

// Get and show any devices or the required device
showDevices(targetDevice)

// Close cleanly
exit(EXIT_SUCCESS)
