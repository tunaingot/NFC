//
//  AppDelegate.swift
//  NFC
//
//  Created by 大川 博 on 2026/03/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
//    private var updater = LUpdate()

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
//        updater.delegate = self
//        updater.checkUpdateAtAppLaunch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

//MARK: - updater
//extension AppDelegate: LUpdateURLInformationDelegate, NSMenuItemValidation {
//    var jsonFileRawURL: String { "https://raw.githubusercontent.com/tunaingot/NFC-Distribute/refs/heads/main/latest.json" }
//    var distributeURL: String { "https://github.com/tunaingot/NFC-Distribute" }
//    
//    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//        return true
//    }
//    
//
//    /*==========================================================================
//     
//     =========================================================================*/
//    @IBAction func checkeUpdate(_ sender: Any?) {
//        updater.checkUpdate()
//    }
//    
//    @IBAction func gotoDistrobuteWebSite(_ sender: Any?) {
//        updater.gotoDistrobuteWebsite()
//    }
//}
