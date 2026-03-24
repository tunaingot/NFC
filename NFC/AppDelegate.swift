//
//  AppDelegate.swift
//  NFC
//
//  Created by 大川 博 on 2026/03/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {


//    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        // Insert code here to initialize your application
//    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

//MARK: - template replacement
extension AppDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

