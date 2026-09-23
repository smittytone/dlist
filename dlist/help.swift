/*
    dlist
    help.swift

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
import Clicore


extension Dlist  {

    /**
     Display help.
     */
    internal static func showHelp() {

        let dlist = "\(String(.bold))dlist\(String(.normal))"
        let helpText = """

        Call \(dlist) to view or use a connected adaptor board's device path. If multiple adaptors are
        connected, \(dlist) will list them. In this case, to use one of them, call \(dlist) with the
        required adaptor board's index as shown in the presented list.

        \(String(.bold))USAGE\(String(.normal))
          dlist [--info] [--version] [--help] [device index]

        \(String(.bold))OPTIONS\(String(.normal))
          -i | --info          Present extra, human-readable device info: product type, manufacturer
          -s | --silent        Silence the 'no connected devices' output when piping output to other apps
          -v | --version       \(dlist) version information
          -h | --help          This help screen

        \(String(.bold))EXAMPLES\(String(.normal))
          One device connected:                  minicom -d $(dlist) -b 9600
          One device connected, get info:        dlist -i
          Two devices connected, use number 1:   minicom -d $(dlist 1) -b 9600
          Two devices connected, get info on 2:  dlist -i 2

        """

        showHeader()
        Stdio.report(helpText)
    }


    /**
     Display the app's version number.
     */
    internal static func showHeader() {

#if os(macOS)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? SWIFT_BUILD_PROCESS_VERSION
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "\(SWIFT_BUILD_PROCESS_BUILD)"
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "dlist"
        Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal)) for macOS")
#else
        // Linux output
        Stdio.report("\(String(.bold))dlist \(SWIFT_BUILD_PROCESS_VERSION) (\(SWIFT_BUILD_PROCESS_BUILD))\(String(.normal)) for Linux")
#endif
        Stdio.report("Copyright © 2026, Tony Smith (@smittytone). Source code available under the MIT licence.")
    }

}
