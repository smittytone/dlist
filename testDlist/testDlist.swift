//
//  testDlist.swift
//  testDlist
//
//  Created by Tony Smith on 14/02/2025.
//

import XCTest

final class testDlist: XCTestCase {
    
    var testDevices: [String: SerialDeviceInfo] = [:]
    let deviceNames: [String] = ["cu.usbmodem01", "cu.usbmodem02"]
    let devicePath = "/dev/"
    let ignorables: [String] = getIgnorables()

    override func setUpWithError() throws {

        var testDevice1 = SerialDeviceInfo()
        testDevice1.vendorName = "ALPHA"
        testDevice1.productType = "A TYPE"
        self.testDevices[self.devicePath + self.deviceNames[0]] = testDevice1
        
        var testDevice2 = SerialDeviceInfo()
        testDevice2.vendorName = "BETA"
        testDevice2.productType = "B TYPE"
        self.testDevices[self.devicePath + self.deviceNames[1]] = testDevice2
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /*
     Should output "no devices" on STDERR
     */
    func testShowDevices_NoDevice_NoInfo() throws {
        
        let devices: [String] = []
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], -1, ignorables[...])

        // Pause until we have data from the pipe
        var a = 0
        while !og.doneflag{
            a += 1
        }
        _ = og.closeConsolePipe()
        
        let expected = "No connected devices\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected)
    }
    
    /*
     Should output devices[0] on STDOUT
     */
    func testShowDevices_OneDevice_NoInfo() throws {
        
        let devices: [String] = [self.deviceNames[0]]
        let og = OutputGrabber.init(useStdout: true)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], -1, ignorables[...])

        // Pause until we have data from the pipe
        var a = 0
        while !og.doneflag{
            a += 1
        }
        _ = og.closeConsolePipe()
        
        let expected = devices[0] + "\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected)
    }
    
    /*
     Should output devices[0] + info on STDERR
     */
    func testShowDevices_OneDevice_Info() throws {

        let devices: [String] = [self.deviceNames[0]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = true
        Dlist.showDevices(devices[...], -1, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = "1. " + devices[0] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected)
    }
    
    /*
     Should output error on STDERR
     */
    func testShowDevices_OneDevice_NoInfo_BadIndex() throws {
        
        let devices: [String] = [self.deviceNames[0]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], 42, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = "\u{1b}[33m\u{1b}[1mWARNING \u{1b}[0m42 is out of range (1)\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected, "\(og.contents)")
    }
    
    /*
     Should output error on STDERR
     */
    func testShowDevices_OneDevice_Info_BadIndex() throws {
        
        let devices: [String] = [self.deviceNames[0]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = true
        Dlist.showDevices(devices[...], 42, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = "\u{1b}[33m\u{1b}[1mWARNING \u{1b}[0m42 is out of range (1-1)\n"
        XCTAssert(og.errors.count == 0 && og.contents.hasPrefix(expected), "\(og.contents)")
    }
    
    /*
     Should output devices[0] + info and devices[1] + info on STDERR
     */
    func testShowDevices_TwoDevices_NoInfo() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], -1, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        
        var expected = "1. " + devices[0] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        expected += "2. " + devices[1] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected, "\(og.contents)")
    }
    
    /*
     Should output devices[0] + info and devices[1] + info on STDERR (identical to above)
     */
    func testShowDevices_TwoDevices_Info() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = true
        Dlist.showDevices(devices[...], -1, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        var expected = "1. " + devices[0] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        expected += "2. " + devices[1] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected, "\(og.contents)")
    }
    
    /*
     Should output devices[1] on STDOUT
     */
    func testShowDevices_TwoDevices_OneSpecified_NoInfo() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: true)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], 2, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = devices[1] + "\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected)
    }
    
    /*
     Should output devices[0] + info on STDERR
     */
    func testShowDevices_TwoDevices_OneSpecified_Info() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = true
        Dlist.showDevices(devices[...], 2, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = devices[1] + "\t\t[UNKNOWN PRODUCT TYPE, UNKNOWN MANUFACTURER]\n"
        XCTAssert(og.errors.count == 0 && og.contents == expected)
    }

    /*
     Should show error on STDERR
     */
    func testShowDevices_TwoDevices_OneSpecified_NoInfo_BadIndex() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = false
        Dlist.showDevices(devices[...], 42, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = "\u{1b}[33m\u{1b}[1mWARNING \u{1b}[0m42 is out of range (1-2)\n"
        XCTAssert(og.errors.count == 0 && og.contents.hasPrefix(expected), "\(og.contents)")
    }
    
    /*
     Should show error on STDERR
     */
    func testShowDevices_TwoDevices_OneSpecified_Info_BadIndex() throws {
        
        let devices: [String] = [self.deviceNames[0], self.deviceNames[1]]
        let og = OutputGrabber.init(useStdout: false)
        og.openConsolePipe()
        
        doShowData = true
        Dlist.showDevices(devices[...], 42, ignorables[...])

        var a = 0
        while !og.doneflag{
            a += 1
        }
        
        _ = og.closeConsolePipe()
        
        let expected = "\u{1b}[33m\u{1b}[1mWARNING \u{1b}[0m42 is out of range (1-2)\n"
        XCTAssert(og.errors.count == 0 && og.contents.hasPrefix(expected), "\(og.contents)")
    }
    
    /*
     Should reject macOS file
     */
    func testDoKeepDevice_DoRemove_01() throws {
        
        XCTAssert(!doKeepDevice("/dev/cu.Bluetooth-Incoming-Port", ignorables[...]))
    }
    
    /*
     Should reject macOS file
     */
    func testDoKeepDevice_DoRemove_02() throws {
        
        XCTAssert(!doKeepDevice("/dev/cu.debug-console", ignorables[...]))
    }
    
    /*
     Should accept USB modem file
     */
    func testDoKeepDevice_DoKeep() throws {
        
        XCTAssert(doKeepDevice("/dev/cu.usbmodem1101", ignorables[...]))
    }
}
