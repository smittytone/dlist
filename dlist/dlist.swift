/*
    dlist
    dlist.swift

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

import Foundation
import Clicore


struct Dlist {

    /**
     Get a list of possible devices from the `/dev` directory.
     At this point we don't parse the list: we just obtain it, but
     we only include those devices prefixed `cu.`.

     - Returns An array of the items in `/dev`.
     */
    static func getDevices(from devicesPath: String) -> [String] {

        var list: [String] = []
        var finalList: [String] = []
        let fm = FileManager.default

        // Get the files in the target directory
        do {
            list = try fm.contentsOfDirectory(atPath: devicesPath)
        } catch {
            Stdio.reportErrorAndExit("\(devicesPath) cannot be found", 2)
            // --------------------------- END --------------------------
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
     List any and all available connected MCUs.

     If only one is available, write its path to STDOUT for piping.

     If multiple are available, write their paths as a table to STDERR so the user
     can select one of them by calling `dlist` with its index as an argument.

     If a selected device is available, write is path to STDOUT for piping.

     If no devices are present, write a warning to STDERR.

     - Parameters:
        - targetDevice The index of a specified device on a dlist-generated list.
     */
    static func showDevices(_ deviceList: ArraySlice<String>, _ targetDevice: Int) {

        if deviceList.count > 0 {
            if deviceList.count == 1 && !doShowData {
                // Warn if a device has been specified anyway
                if targetDevice != -1 && targetDevice != 1 {
                    Stdio.reportWarning("\(targetDevice) is out of range (1)")
                }

                // Write the path of the only device to STDOUT
                Stdio.output(DEVICE_PATH + deviceList[0])
            } else {
                // Check any specified index is valid
                var useDevice = targetDevice
                if useDevice > deviceList.count {
                    Stdio.reportWarning("\(targetDevice) is out of range (1-\(deviceList.count))")
                    useDevice = -1
                }

                // Write the path of the valid chosen device to STDOUT
                if useDevice != -1 && !doShowData {
                    Stdio.output(DEVICE_PATH + deviceList[useDevice - 1])
                    return
                }

                // List devices to STDERR (ie. for humans)
#if os(macOS)
                let deviceData = findConnectedSerialDevices()
#endif
                var count = 1
                for device in deviceList {
#if os(macOS)
                    let sd = deviceData[DEVICE_PATH + device] ?? SerialDeviceInfo()
#else
                    let sd = getDeviceInfo(device)
#endif

                    if useDevice == -1 {
                        // No device specified so output all
                        Stdio.report(String(format: "%d. %@\t\t[%@, %@]", count, DEVICE_PATH + device, sd.productType, sd.vendorName))
                    } else if useDevice == count {
                        // Device specified so no need to present its index
                        Stdio.report(String(format: "%@\t\t[%@, %@]", DEVICE_PATH + device, sd.productType, sd.vendorName))
                    }

                    count += 1
                }
            }
        } else {
            Stdio.report("No connected devices")
        }
    }
}
