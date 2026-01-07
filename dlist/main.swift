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
import Clicore


// MARK: Constants

let DEVICE_PATH             = "/dev/"
let SYS_PATH_LINUX          = "/sys/class/tty/"
/* The following is retained as part of the Linux device alias code and may be removed
let UDEV_RULES_PATH_LINUX   = "/etc/udev/rules.d/99-dlist-usb-serial-devices.rules"
*/


// MARK: Global Variables

// CLI argument management
var argIsAValue         = false
var argType             = -1
var argCount            = 0
var prevArg             = ""
// App control
var targetDevice        = -1
var doShowData          = false
/* The following is retained as part of the Linux device alias code and may be removed
var doApplyAlias        = false
var alias               = ""
// Computed
var isRunAsSudo: Bool {
    // This is required on Linux for access to Linux Udev rules.
    get {
        if let value: String = ProcessInfo.processInfo.environment["USER"] {
            return (value == "root")
        }

        return false
    }
}
*/


// MARK: Runtime Start

// Set up Ctrl-C trap
Stdio.enableCtrlHandler("dlist interrupted -- halting")

#if os(macOS)
// FROM 0.1.5
let ignorableDevices = getIgnorables()
#endif

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
            Stdio.reportErrorAndExit("Missing value for \(prevArg)")
            // ------------------------ END ------------------------
        }
    } else {
        switch argument {
            case "-i", "--info":
                doShowData = true
            case "-h", "--help":
                showHelp()
                closeCleanly()
            case "-v", "--version":
                showHeader()
                closeCleanly()
            default:
                if argument.prefix(1) == "-" {
                    Stdio.reportErrorAndExit("Unknown argument: \(argument)")
                    // ------------------------- END ------------------------
                }

                // Get the device choice and convert string arg to int
                if let deviceChoice = Int(argument) {
                    // Make sure zero was not provided
                    if deviceChoice == 0 {
                        Stdio.reportErrorAndExit("Device reference \(argument) is invalid (zero)")
                        // --------------------------------- END ---------------------------------
                    }

                    targetDevice = deviceChoice
                }
        }

        prevArg = argument
    }

    argCount += 1

    // Trap commands that come last and therefore have missing args
    if argCount == CommandLine.arguments.count && argIsAValue {
        Stdio.reportErrorAndExit("Missing value for \(argument)")
        // ------------------------- END ------------------------
    }
}

// Get a list of appropriate devices
#if os(macOS)
let deviceList = Dlist.getDevices(from: DEVICE_PATH)
#elseif os(Linux)
let deviceList = Dlist.getDevices(from: SYS_PATH_LINUX)
#endif

// Show a list of devices or the required device
Dlist.showDevices(deviceList[...], targetDevice)

// Close cleanly
closeCleanly()

// MARK: Runtime End


// MARK: Help and Info Functions

/**
 Display help.
 */
private func showHelp() {

    showHeader()
    Stdio.report("\n\(String(.bold))MISSION\(String(.normal))\n  List connected USB-to-serial adaptors.\n")
    Stdio.report("\(String(.bold))USAGE\(String(.normal))\n  dlist [--info] [--version] [--help] [device index]\n")
    Stdio.report("Call \(String(.italic))dlist\(String(.normal)) to view or use a connected adaptor's device path. If multiple adaptors are connected,")
    Stdio.report("\(String(.italic))dlist\(String(.normal)) will list them. In this case, to use one of them, call \(String(.italic))dlist\(String(.normal)) with the required")
    Stdio.report("adaptor's index as shown in the presented list.\n")
    Stdio.report("\(String(.bold))OPTIONS\(String(.normal))\n")
    Stdio.report("  -i | --info          Present extra, human-readable device info: product type, manufacturer")
    Stdio.report("  -v | --version       Utility version information")
    Stdio.report("  -h | --help          This help screen\n")
    Stdio.report("\(String(.bold))EXAMPLES\(String(.normal))")
    Stdio.report("  One device connected:                  minicom -d $(dlist) -b 9600")
    Stdio.report("  One device connected, get info:        dlist -i")
    Stdio.report("  Two devices connected, list them:      dlist")
    Stdio.report("  Two devices connected, use number 1:   minicom -d $(dlist 1) -b 9600")
    Stdio.report("  Two devices connected, get info on 2:  dlist -i 2\n")
}


/**
 Display the app's version number.
 */
private func showHeader() {

#if os(macOS)
    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    let name:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal)) for macOS")
#else
    // Linux output
    // TODO Automate based on build settings
    Stdio.report("\(String(.bold))dlist \(LINUX_VERSION) (\(LINUX_BUILD))\(String(.normal)) for Linux")
#endif
    Stdio.report("Copyright © 2025, Tony Smith (@smittytone). Source code available under the MIT licence.")
}


/**
 Close the utility cleanly.
 */
private func closeCleanly() {

    Stdio.disableCtrlHandler()
    exit(EXIT_SUCCESS)  
}
