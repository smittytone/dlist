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
#if os(Linux)
import Clibudev
#endif


// MARK: - Constants

let DEVICE_PATH             = "/dev/"
let SYS_PATH_LINUX          = "/sys/class/tty/"
let UDEV_RULES_PATH_LINUX   = "/etc/udev/rules.d/99-dlist-usb-serial-devices.rules"


// MARK: - Global Variables

// CLI argument management
var argIsAValue         = false
var argType             = -1
var argCount            = 0
var prevArg             = ""
// App control
var doApplyAlias        = false
var doShowData          = false
var alias               = ""
var targetDevice        = -1
// Computed
var isRunAsSudo: Bool {
    // This is required on Linux for access to `UDEV_RULES_PATH_LINUX`.
    get {
        if let value: String = ProcessInfo.processInfo.environment["USER"] {
            return (value == "root")
        }

        return false
    }
}


// MARK: - Functions

/**
    Get a list of possible devices from the `/dev` directory.
    At this point we don't parse the list: we just obtain it, but
    we only include those devices prefixed `cu.`.
 
    - Returns An array of the items in `/dev`.
 */
internal func getDevices(from devicesPath: String) -> [String] {
    
    var list: [String] = []
    var finalList: [String] = []
    let fm = FileManager.default

    // Get the files in the target directory
    do {
        list = try fm.contentsOfDirectory(atPath: devicesPath)
    } catch {
        reportErrorAndExit("\(devicesPath) cannot be found", 2)
    }
    
    // For macOS, we just look out for devices in `/dev` prefixed `cu.`,
    // and make sure we ignore macOS-added items, eg. `cu.Bluetooth-Incoming`.
#if os(macOS)
    for device in list {
        if device.hasPrefix("cu.") && doKeepDevice(device) {
            finalList.append(device)
        }
    }
    
    // We need a narrower focus for Linux: devices will be `/dev/ttyUSBx` or `/dev/ttyACMx`.
    // These are listed even if no device is connected, so we check `/sys/class/tty/ttyUSB*` and
    // `/sys/class/tty/ttyACM*` which only appear when devices *are* connected
#elseif os(Linux)
    for device in list {
        if device.hasPrefix("ttyUSB") || device.hasPrefix("ttyACM") {
            finalList.append(device)
        }
    }
#endif

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
internal func pruneDevices(_ devices: [String]) -> [String] {
    
    guard devices.count > 0 else { return devices }
    
    // This is the list of known `cu.` devices that are definitely not MCUs
    // NOTE These are implicitly absent under Linux
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
internal func showDevices(_ targetDevice: Int) {
    
#if os(macOS)
    let deviceList = getDevices(from: DEVICE_PATH)
#elseif os(Linux)
    let deviceList = getDevices(from: SYS_PATH_LINUX)
#endif

    //let shortList = pruneDevices(baseList)
    if deviceList.count > 0 {
        if deviceList.count == 1 && !doShowData {
            // Warn if a device has been specified anyway
            if targetDevice != -1 && targetDevice != 1 {
                reportWarning("\(targetDevice) is out of range (1)")
            }
            
            // Write the path of the only device to STDOUT
            writeToStdout(DEVICE_PATH + deviceList[0])
        } else {
#if os(macOS)
            let deviceData = findConnectedSerialDevices()
#endif
            var useDevice = targetDevice
            if useDevice > deviceList.count {
                reportWarning("\(targetDevice) is out of range (1-\(deviceList.count))")
                useDevice = -1
            }
            
            // Write the path of the valid chosen device to STDOUT
            if useDevice != -1 {
                writeToStdout(DEVICE_PATH + deviceList[useDevice - 1])
                return
            }
            
            // List devices to STDERR (ie. for humans)
            var count = 1
            for device in deviceList {// List devices to STDERR (ie. for humans)
#if os(macOS)
                let sd = deviceData[DEVICE_PATH + device] ?? SerialDeviceInfo()
#else
                let sd = getDeviceInfo(device)
#endif
                reportInfo(String(format: "%d. %@\t\t[%@, %@]", count, DEVICE_PATH + device, sd.productType, sd.vendorName))
                count += 1
            }
        }
    } else {
        reportInfo("No connected devices")
    }
}


/**
    Display help
 */
private func showHelp() {

    showVersion()
    writeToStdout(BOLD + "MISSION" + RESET + "\n  List connected USB-to-serial adaptors.\n")
    writeToStdout(BOLD + "USAGE" + RESET + "\n  dlist [--info] [--help] [device index]\n")
    writeToStdout("Call " + ITALIC + "dlist" + RESET + " to view or use a connected adaptor's device path. If multiple adaptors are connected,")
    writeToStdout(ITALIC + "dlist" + RESET + " will list them. In this case, to use one of them, call " + ITALIC + "dlist" + RESET + " with the required")
    writeToStdout("adaptor's index as shown in the presented list.\n")
    writeToStdout(BOLD + "OPTIONS" + RESET + "\n")
    writeToStdout("  -i | --info          Present extra, human-readable device info: product type, manufacturer")
    writeToStdout("  -h | --help          This help screen\n")
    writeToStdout(BOLD + "EXAMPLES" + RESET)
    writeToStdout("  One device connected:                  minicom -d $(dlist) -b 9600")
    writeToStdout("  Two devices connected, use number 1:   minicom -d $(dlist 1) -b 9600\n")
}


/**
    Display the app version.
 */
func showVersion() {

    showHeader()
    writeToStdout("Copyright © 2025, Tony Smith (@smittytone). Source code available under the MIT licence.\n")
}


/**
    Display the app's version number.
 */
func showHeader() {
    
#if os(macOS)
    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    writeToStdout(BOLD + "\(name) \(version) (\(build))" + RESET)
#else
    // Linux output
    // TODO Automate based on build settings
    writeToStdout(BOLD + "dlist \(LINUX_VERSION) (\(LINUX_BUILD))" + RESET)
#endif
}


// MARK: - Runtime Start

// Set up Ctrl-C trap
configureSignalHandling()

// Process the (separated) arguments
for argument in CommandLine.arguments {
    // Ignore the first argument
    if argCount == 0 {
        argCount += 1
        continue
    }

    if argIsAValue {
        // Make sure we're not reading in an option rather than a value
        if argument.prefix(1) == "-" {
            reportErrorAndExit("Missing value for \(prevArg)")
        }

        switch argType {
        case 0:
            alias = argument
            doApplyAlias = true
        default:
            reportErrorAndExit("Unknown argument: \(argument)")
        }

        argIsAValue = false
    } else {
        switch argument {
            case "-a":
                fallthrough
            case "--alias":
                argType = 0
                argIsAValue = true
            case "-i":
                fallthrough
            case "--info":
                doShowData = true
            case "-h":
                fallthrough
            case "--help":
                showHelp()
                exit(EXIT_SUCCESS)
            case "--version":
                showVersion()
                exit(EXIT_SUCCESS)
            default:
                if argument.prefix(1) == "-" {
                    reportErrorAndExit("Unknown argument: \(argument)")
                }
                
                // Get the device choice and convert string arg to int
                if let deviceChoice = Int(argument) {
                    // Make sure zero was not provided
                    if deviceChoice == 0 {
                        reportErrorAndExit("Device reference \(argument) is invalid (zero)")
                    }
                    
                    targetDevice = deviceChoice
                }
        }

        prevArg = argument
    }

    argCount += 1

    // Trap commands that come last and therefore have missing args
    if argCount == CommandLine.arguments.count && argIsAValue {
        reportErrorAndExit("Missing value for \(argument)")
    }
}

if !alias.isEmpty {
    print("ALIAS: \(alias)")
}

// Get and show any devices or the required device
showDevices(targetDevice)

// Close cleanly
exit(EXIT_SUCCESS)
