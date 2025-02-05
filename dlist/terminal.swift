/*
    <generic>
    terminal.swift

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


// File handles
let STD_ERR: FileHandle         = FileHandle.standardError
let STD_OUT: FileHandle         = FileHandle.standardOutput
// TTY formatting
let RED: String                 = "\u{001B}[0;31m"
let YELLOW: String              = "\u{001B}[0;33m"
let RESET: String               = "\u{001B}[0m"
let BOLD: String                = "\u{001B}[1m"
let ITALIC: String              = "\u{001B}[3m"
let BSP: String                 = String(UnicodeScalar(8))
// Signalling
let EXIT_CTRL_C_CODE: Int32 = 130
let CTRL_C_MSG: String          = "\(BSP)\(BSP)\rpdfmaker interrupted -- halting"


var doShowInfo: Bool            = false
let dss: DispatchSourceSignal   = DispatchSource.makeSignalSource(signal: SIGINT,
                                                                  queue: DispatchQueue.main)


/**
    Generic error display routine that also quits the app.

    - Parameters
        - message: The text to print.
        - code:    The shell `exit` error code.
 */
func reportErrorAndExit(_ message: String, _ code: Int32 = EXIT_FAILURE) {

    writeToStderr(RED + BOLD + "ERROR" + RESET + " " + message + " -- exiting")
    dss.cancel()
    exit(code)
}


/**
    Generic warning display routine.

    - Parameters
        - message: The text to print.
 */
func reportError(_ message: String) {

    writeToStderr(RED + BOLD + "ERROR" + RESET + " " + message)
}


/**
    Generic warning display routine.

    - Parameters
        - message: The text to print.
 */
func reportWarning(_ message: String) {

    writeToStderr(YELLOW + BOLD + "WARNING" + RESET + " " + message)
}


/**
    Post extra information but only if requested by the user.

    - Parameters
        - message: The text to print.
 */
func reportInfo(_ message: String) {
    
    writeToStderr(message)
}


/**
    Post extra information but only if requested by the user.

    - Parameters
        - message: The text to print.
 */
func reportDebugInfo(_ message: String) {
    
    if doShowInfo {
        writeToStderr(message)
    }
}


/**
    Issue the supplied text to `STDERR`.

    - Parameters
        - message The text to print.
 */
func writeToStderr(_ message: String) {

    writeOut(message, STD_ERR)
}


/**
    Issue the supplied text to `STDOUT`.

    - Parameters
        - message: The text to print.
 */
func writeToStdout(_ message: String) {

    writeOut(message, STD_OUT)
}


/**
    Generic text output routine.

    - Parameters
        - message:          The text to print.
        - targetFileHandle: Where the message will be sent.
 */
func writeOut(_ message: String, _ targetFileHandle: FileHandle) {

    let messageAsString = message + "\n"
    if let messageAsData: Data = messageAsString.data(using: .utf8) {
        targetFileHandle.write(messageAsData)
    }
}


internal func configureSignalHandling() {
    
    // Make sure the signal does not terminate the application
    signal(SIGINT, SIG_IGN)

    // ...add an event handler
    dss.setEventHandler {
        writeToStderr(CTRL_C_MSG)
        dss.cancel()
        exit(EXIT_CTRL_C_CODE)
    }

    // ...and start the event flow
    dss.resume()
}
