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


// MARK: - Global Variables

// CLI argument management
var argIsAValue: Bool   = false
var argType: Int        = -1
var argCount: Int       = 0
var prevArg: String     = ""
// App-specific Variables
var targetDevice        = -1


/*
 * FUNCTIONS
 */

/**
    Get a list of possible devices from the `/dev` directory.
    At this point we don't parse the list: we just obtain it, but
    we only include those devices prefixed `cu.`.
 
    - Returns An array of the items in `/dev`.
 */
private func getDevices() -> [String] {
    
    var list: [String] = []
    var finalList: [String] = []
    let fm = FileManager.default
    
    list = try! fm.contentsOfDirectory(atPath: "/dev")
    
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
 */
private func showDevices() {
    
    let baseList = getDevices()
    let shortList = pruneDevices(baseList)

    if shortList.count > 0 {
        if shortList.count == 1 {
            // Write the path of the only device to STDOUT
            writeToStdout(shortList[0])
        } else {
            var count = 1
            for device in shortList {
                if targetDevice != -1 && count == targetDevice {
                    // Write the path of the chosen device to STDOUT
                    writeToStdout(device)
                } else {
                    // List devices to STDERR (ie. for humans)
                    let output = String(format: "%03d. ", count)
                    reportInfo(output + device)
                }
                
                count += 1
            }
        }
    } else {
        reportWarning("No connected devices")
    }
}



/*
 * RUNTIME START
 */

// Set up Ctrl-C trap
configureSignalHandling()

// Expand composite flags
var args: [String] = []
for arg in CommandLine.arguments {
    // Look for compound flags, ie. a single dash followed by
    // more than one flag identifier
    if arg.prefix(1) == "-" && arg.prefix(2) != "--" {
        if arg.count > 2 {
            // arg is of form '-mfs'
            for sub_arg in arg {
                // Check for and ignore interior dashes
                // eg. in `-mf-l`
                if sub_arg == "-" {
                    continue
                }
                
                // Retain the flag as a standard arg for subsequent processing
                args.append("-\(sub_arg)")
            }

            continue
        }
    }
    
    // It's an ordinary arg, so retain it
    args.append(arg)
}


// Process the (separated) arguments
for argument in args {
    // Ignore the first comand line argument
    if argCount == 0 {
        argCount += 1
        continue
    }
    
    if let deviceChoice = Int(argument) {
        targetDevice = deviceChoice
    } else {
        reportErrorAndExit("Device reference is not an integer. List available devices to get this value.")
    }

    argCount += 1
}

// Get and show any devices or the required device
showDevices()

// Close cleanly
exit(EXIT_SUCCESS)
