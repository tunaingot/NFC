//
//  LLocalizer.swift
//  Cycle Computer 2
//
//  Created by 大川 博 on 2026/01/28.
//

import Cocoa

class LLocalizer: NSObject {
    private let SELF_LOCALIZE_DIC = ["Unable to parse the contents of the localization file." : "ローカライズファイルの内容を解析できませんでした",
                                     "Localization file not found" : "ローカライズファイルが見つかりませんでした"]
    
    /*==========================================================================
     
     ==========================================================================*/
    private(set) var localizeFileURL: URL?
    private var dictionary = [String : String]()
    
    /*==========================================================================
     
     ==========================================================================*/
    init(stringFileName: String) {
        super.init()
        
        if let url = Bundle.main.url(forResource: stringFileName, withExtension: "strings") {
            localizeFileURL = url
            
            do {
                let data = try Data(contentsOf: url)
                
                dictionary = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String : String]
            } catch {
                print(SELF_LOCALIZE_DIC["Unable to parse the contents of the localization file."]!)
            }
            
        } else {
            print(SELF_LOCALIZE_DIC["Localization file not found"]!)
        }
    }
    /*==========================================================================
     
     ==========================================================================*/
    public func localize(_ key: String) -> String {
        return dictionary[key] ?? key
    }
}
