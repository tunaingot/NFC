//
//  extensions.swift
//  NFC
//
//  Created by 大川 博 on 2026/03/26.
//

import Foundation
import Cocoa

public func dprint(
    _ items: Any...,
) {
    Swift.print(items)
}

extension String {
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    public var isDirectory: Bool {
        return FileManager.default.isDirectory(atPath: self)
    }
    public var pathExtension: String? {
        if let start = lastIndex(of: Character(".")) {
            if String(self[index(start, offsetBy: 1) ..< endIndex]).contains("/") { //ディレクトリ内の.を検出した
                return nil
            }
            return String(self[index(start, offsetBy: 1) ..< endIndex])
        } else {
            return nil
        }
    }
    public var deletingPathExtension: String {
        let result = self//lastPathComponent
        
        if isDirectory {
            return result
        } else if let pos = result.lastIndex(of: Character(".")) {
            return String(result[startIndex ..< pos])
        } else {    //拡張子が存在しない
            return result
        }
    }
}

extension NSButton {
    public var isOn: Bool {
        get {
            if state == NSControl.StateValue(1) {
                return true
            } else {
                return false
            }
        }
        set {
            if newValue == true {
                state = NSControl.StateValue(1)
            } else {
                state = NSControl.StateValue(0)
            }
        }
    }
}

extension Bool {
    public func save(forKey saveKey: String) {
        let currentSaveValue = UserDefaults.standard.bool(forKey: saveKey)
        
        if currentSaveValue != self {
            UserDefaults.standard.setValue(self, forKey: saveKey)
            UserDefaults.standard.synchronize()
        }
    }
    public static func load(forKey saveKey: String) -> Bool {
        return UserDefaults.standard.bool(forKey: saveKey)
    }
}

extension Int {
    public func save(forKey saveKey: String) {
        UserDefaults.standard.setValue(self, forKey: saveKey)
        UserDefaults.standard.synchronize()
    }
    public static func load(forKey saveKey: String) -> Int {
        return UserDefaults.standard.integer(forKey: saveKey)
    }
}

extension FileManager {
    public func isDirectory(atPath: String) -> Bool {
        var isDir: ObjCBool = false
        
        FileManager.default.fileExists(atPath: atPath, isDirectory: &isDir)
        
        return isDir.boolValue
    }
}

extension NSApplication {
    public class var name: String {
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        return "UnknownApp"
    }
}

extension NSAlert {
    ///Cancelボタンが不要なときはcancelTitleにnilを入れる
    public static func informativeAlert(okTitle: String, cancelTitle: String?, message: String) -> NSAlert {
        let alert = NSAlert()
        let okButton = alert.addButton(withTitle: okTitle)
        
        okButton.tag = NSApplication.ModalResponse.OK.rawValue
        alert.alertStyle = .informational
        alert.messageText = message

        if cancelTitle != nil {
            let cancelButton = alert.addButton(withTitle: cancelTitle!)
            
            cancelButton.tag = NSApplication.ModalResponse.cancel.rawValue
        }
        
        return alert
    }
    
    ///Cancelボタンが不要なときはcancelTitleにnilを入れる
    public static func criticalAlert(okTitle: String, cancelTitle: String?, message: String) -> NSAlert {
        let alert = NSAlert()
        let okButton = alert.addButton(withTitle: okTitle)
        
        okButton.tag = NSApplication.ModalResponse.OK.rawValue
        alert.alertStyle = .critical
        alert.messageText = message
        
        if cancelTitle != nil {
            let cancelButton = alert.addButton(withTitle: cancelTitle!)
            
            cancelButton.tag = NSApplication.ModalResponse.cancel.rawValue
        }
        
        return alert
    }
    
    ///Cancelボタンが不要なときはcancelTitleにnilを入れる
    public static func warningAlert(okTitle: String, cancelTitle: String?, message: String) -> NSAlert {
        let alert = NSAlert()
        let okButton = alert.addButton(withTitle: okTitle)
        
        okButton.tag = NSApplication.ModalResponse.OK.rawValue
        alert.alertStyle = .warning
        alert.messageText = message
        
        if cancelTitle != nil {
            let cancelButton = alert.addButton(withTitle: cancelTitle!)
            
            cancelButton.tag = NSApplication.ModalResponse.cancel.rawValue
        }
        
        return alert
    }
}

extension NSSound {
    public static var soundList: [String] {
        var result = [String]()
        let paths = [
            "/System/Library/Sounds",
            "/Library/Sounds",
            NSHomeDirectory() + "/Library/Sounds"
        ]
        
        for path in paths {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: path)
                
                for file in files {
                    if file.pathExtension == "aiff" {
                        result.append(file.deletingPathExtension)
                    }
                }
            } catch {
                
            }
        }
        return result
    }
}
