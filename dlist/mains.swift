/*
    dlist
    mains.swift

    Copyright © 2026 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
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


@main
struct Dlist {

    /**
     Primary CLI entry point called by OS
     */
    static func main() {

        var settings = Settings()

#if os(macOS)
        // FROM 0.2.4
        // Use emoji markers on macOS
        Stdio.settings.useEmoji = true
#endif

        // Set up Ctrl-C trap
        Stdio.enableCtrlHandler("dlist interrupted -- halting")

        // Process the (separated) arguments
        let collatedArguments = Cli.unify(args: CommandLine.arguments)
        for argument in collatedArguments {
            switch argument {
                case "-i", "--info":
                    settings.showData = true
                case "-h", "--help":
                    showHelp()
                    closeCleanly()
                case "-v", "--version":
                    showHeader()
                    closeCleanly()
                case "-s", "--silent":
                    settings.silenceNoDevicesWarning = true
                default:
                    if argument.prefix(1) == "-" {
                        Stdio.reportErrorAndExit("Unknown argument: \(argument)")
                    }

                    // Get the device choice and convert string arg to int
                    if let deviceChoice = Int(argument) {
                        // Make sure zero was not provided
                        if deviceChoice == 0 {
                            Stdio.reportErrorAndExit("Device reference \(argument) is invalid (zero)")
                        }

                        settings.targetDevice = deviceChoice
                    } else {
                        Stdio.reportErrorAndExit("Device reference \(argument) is invalid")
                    }
            }
        }
        
        // Get a list of appropriate devices
#if os(macOS)
        let ignorableDevices = Dlist.getIgnorables()
        let deviceList = Dlist.getDevices(from: settings.DEV_DIR_PATH, ignorableDevices[...])
#elseif os(Linux)
        let ignorableDevices: [String] = []
        let deviceList = Dlist.getDevices(from: settings.SYS_PATH_LINUX, ignorableDevices[...])
#endif

        // Show a list of devices or the required device
        Dlist.showDevices(deviceList[...], ignorableDevices[...], settings)

        // Close cleanly
        closeCleanly()
    }


    /**
     Close the utility correctly.
     */
    private static func closeCleanly() {

        Stdio.disableCtrlHandler()
        exit(EXIT_SUCCESS)
    }
}
