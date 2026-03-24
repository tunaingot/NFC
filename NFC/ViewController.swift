//
//  ViewController.swift
//  NFC
//
//  Created by 大川 博 on 2026/03/23.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var readUIDButton: NSButton!
    
    @IBOutlet weak var autoReadingCheck: NSButton!
    @IBOutlet weak var uidField: NSTextField!
    @IBOutlet weak var readPrefixField: NSTextField!
    @IBOutlet weak var readURLPrefixField: NSTextField!
    @IBOutlet weak var readDataField: NSTextField!
    @IBOutlet weak var readBytesLabel: NSTextField!
    @IBOutlet weak var likelyCardLabel: NSTextField!
    @IBOutlet weak var readButton: NSButton!

    @IBOutlet weak var writePrefixField: NSTextField!
    @IBOutlet weak var writeURLPrefixField: NSTextField!
    @IBOutlet weak var writeDataField: NSTextField!
    @IBOutlet weak var writeDataClearButton: NSButton!
    @IBOutlet weak var writeBytesLabel: NSTextField!
    @IBOutlet weak var writableCardLabel: NSTextField!
    @IBOutlet weak var writeButton: NSButton!
    
    @IBOutlet weak var soundPopup: NSPopUpButton!
    
    @IBOutlet weak var autoOpenURLCheck: NSButton!
    @IBOutlet weak var openURLButton: NSButton!

    /*==========================================================================
     
     =========================================================================*/
    private let AUTO_READING_INTERVAL = Double(1)
    private let AUTO_READING_SAVE_KEY = "Auto Reading"
    private let OPEN_URL_AUTOMATICALLY_SAVE_KEY = "Open URL Automatically"
    private let READ_COMPLETE_SOUND_SAVE_KEY = "Read Complete Sound"
    private let WRITE_BYTES_FORMAT = "%d bytes".localized
    private let WRITABLE_CARD_FORMAT = "Writable Card : %@".localized
    private let LIKELY_CARD_FORMAT = "Likely Card : %@".localized
    
    /*==========================================================================
     
     =========================================================================*/
    private var displayedNTAG: LNTAG215?
    private var isCardDetected = false
    private var openURLButtonState: Bool {
        if autoOpenURLCheck.isOn {
            return false
        } else {
            if displayedNTAG == nil {
                return false
            } else {
                if displayedNTAG!.prefix.contains("http") {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    private var writeString: String {
        let prefix = LNTAG215.prefix(of: writeDataField.stringValue)
        
        if prefix == 0 {
            return writeDataField.stringValue
        } else {
            let str = writeDataField.stringValue
            let writeStr = str.replacingOccurrences(of: LNTAG215.urlPrefix(of: prefix), with: "")
            
            return writeStr
        }
    }
    private var writeBytes: Int {
        return writeString.data(using: .utf8)!.count
    }
    private var readBytes: Int {
        let str = readDataField.stringValue
        return str.data(using: .utf8)!.count
    }
    /*==========================================================================
     
     =========================================================================*/

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

//MARK: - template replacement
extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autoReadingCheck.isOn = Bool.load(forKey: AUTO_READING_SAVE_KEY)
        
        uidField.alignment = .center
        uidField.isEditable = false

        readPrefixField.isEnabled = false
        readPrefixField.alignment = .center
        readURLPrefixField.isEnabled = false
        readURLPrefixField.alignment = .right
        readDataField.isEditable = false
        readDataField.focusRingType = .none
        openURLButton.isEnabled = false
        readBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, 0)
        likelyCardLabel.stringValue = String(format: LIKELY_CARD_FORMAT, NTAGCardType.NTAG213.name)
        
//        (readDataField.cell as! PaddedTextFieldCell).rightPadding = 100
        
        writePrefixField.isEnabled = false
        writePrefixField.alignment = .center
        writeURLPrefixField.isEnabled = false
        writeURLPrefixField.alignment = .right
        writeDataField.delegate = self
        writeDataField.focusRingType = .none
        writeBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, 0)
        writableCardLabel.stringValue = String(format: WRITABLE_CARD_FORMAT, NTAGCardType.NTAG213.name)
        writeButton.isEnabled = false
        

        soundPopup.removeAllItems()
        soundPopup.addItems(withTitles: FileManager.default.sounds)
        soundPopup.selectItem(at: Int.load(forKey: READ_COMPLETE_SOUND_SAVE_KEY))

        autoOpenURLCheck.isOn = Bool.load(forKey: OPEN_URL_AUTOMATICALLY_SAVE_KEY)


        if autoReadingCheck.isOn {
            readButton.isEnabled = false
        }
        
        Timer.scheduledTimer(withTimeInterval: AUTO_READING_INTERVAL, repeats: true) { [self] Timer in
            if autoReadingCheck.isOn {
                if LNTAG215.isCardDetected {
                    if isCardDetected == false {
                        isCardDetected = true
                        dprint("Card Detect!")
                        readButton(self)
                    }
                } else {
                    isCardDetected = false
                }
            }
        }
    }
}

//MARK: -
extension ViewController {
    override func viewWillAppear() {
        view.window?.setFrameAutosaveName("Main Window")
        view.window?.title = NSApplication.name
    }
    
    private func playSound() {
        if let sound = NSSound(named: soundPopup.selectedItem!.title) {
            sound.play()
        }
    }
}

//MARK: - action
extension ViewController: NSTextFieldDelegate {
    @IBAction func readUIDButton(_ sender: Any) {
        let NTAG = LNTAG215()
        print(NTAG.UID)
        uidField.stringValue = NTAG.UID
    }
    @IBAction func readButton(_ sender: Any) {
        displayedNTAG = LNTAG215()
        
        print(displayedNTAG!.prefix + displayedNTAG!.payloadString)
        readURLPrefixField.stringValue = displayedNTAG!.prefix
        readPrefixField.stringValue = String(format: "0x%02X", displayedNTAG!.uriPrefix)
        readDataField.stringValue = displayedNTAG!.payloadString
        uidField.stringValue = displayedNTAG!.UID
//        prefixPopup.selectItem(at: 0)
//        writeDataField.stringValue = ""
//        NSSound.beep()
        playSound()
        openURLButton.isEnabled = openURLButtonState
        readBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, readBytes)
        likelyCardLabel.stringValue = String(format: LIKELY_CARD_FORMAT, LNTAG215.writableCard(for: readBytes).name)
        
        if autoOpenURLCheck.isOn {
            if displayedNTAG!.prefix.contains("http") {
                let url = displayedNTAG!.prefix + displayedNTAG!.payloadString
                
                NSWorkspace.shared.open(URL(string: url)!)
            }
        }
        
    }
    @IBAction func writeButton(_ sender: Any) {
        let prefix = LNTAG215.prefix(of: writeDataField.stringValue)
        let writeResult = LNTAG215.write(prefex: prefix, data: writeString.data(using: .utf8)!)
        let alert = NSAlert.informativeAlert(okTitle: "OK", cancelTitle: nil, message: "Write successfully.".localized)
        
        if writeResult == false {
            alert.messageText = "Write Fail !".localized
            alert.alertStyle = .critical
        }
        playSound()

        alert.icon = NSApplication.shared.applicationIconImage
        alert.beginSheetModal(for: view.window!) { [self] response in
            writeButton.isEnabled = false
        }
    }
    @IBAction func autoReadingCheck(_ sender: Any) {
        if autoReadingCheck.isOn {
            readButton.isEnabled = false
        } else {
            readButton.isEnabled = true
        }
        autoReadingCheck.isOn.save(forKey: AUTO_READING_SAVE_KEY)
    }
    @IBAction func autoOpenURLCheck(_ sender: Any) {
        autoOpenURLCheck.isOn.save(forKey: OPEN_URL_AUTOMATICALLY_SAVE_KEY)
        openURLButton.isEnabled = openURLButtonState
    }
    @IBAction func prefixPopup(_ sender: Any) {
        writeBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, writeBytes)
        writableCardLabel.stringValue = String(format: WRITABLE_CARD_FORMAT, LNTAG215.writableCard(for: writeBytes).name)
    }
    @IBAction func soundPopup(_ sender: Any) {
        playSound()
        soundPopup.indexOfSelectedItem.save(forKey: READ_COMPLETE_SOUND_SAVE_KEY)
    }
    @IBAction func openURLButton(_ sender: Any) {
        let prefix = displayedNTAG!.prefix
        let payload = displayedNTAG!.payloadString
        
        NSWorkspace.shared.open(URL(string: prefix + payload)!)
    }
    
    /*==========================================================================
     
     =========================================================================*/
    private func writeDataFieldDidChange() {
        let prefix = LNTAG215.prefix(of: writeDataField.stringValue)
        
        writeURLPrefixField.stringValue = LNTAG215.urlPrefix(of: prefix)
        writeBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, writeBytes)
        writableCardLabel.stringValue = String(format: WRITABLE_CARD_FORMAT, LNTAG215.writableCard(for: writeBytes).name)
        writePrefixField.stringValue = String(format: "0x%02X", prefix)
        
        if writeDataField.stringValue.count > 0 {
            writeButton.isEnabled = true
        } else {
            writeButton.isEnabled = false
        }
    }
    func controlTextDidChange(_ obj: Notification) {
        writeDataFieldDidChange()
    }
    
    @IBAction func writeDataClearButton(_ sender: Any) {
        writeDataField.stringValue = ""
        writeDataFieldDidChange()
    }
}

class PaddedTextFieldCell: NSTextFieldCell {
    public var rightPadding = CGFloat(24)  //右端の余白サイズ

    /*==========================================================================
     テキスト全体の表示・編集エリアを決定するメソッド
     =========================================================================*/
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var rect = super.drawingRect(forBounds: rect)   //ビューの領域を取得
        
        rect.size.width -= rightPadding
        return rect
    }
}
