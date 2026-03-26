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
    @IBOutlet weak var autoOpenURLCheck: NSButton!
    @IBOutlet weak var readDataField: NSTextField!
    @IBOutlet weak var openURLButton: NSButton!
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

    /*==========================================================================
     
     =========================================================================*/
    private let AUTO_READING_INTERVAL = Double(2)
    private let AUTO_READING_SAVE_KEY = "Auto Reading"
    private let OPEN_URL_AUTOMATICALLY_SAVE_KEY = "Open URL Automatically"
    private let READ_COMPLETE_SOUND_SAVE_KEY = "Read Complete Sound"
    private let WRITE_BYTES_FORMAT = "%d bytes".localized
    private let WRITABLE_CARD_FORMAT = "Writable Card : %@".localized
    private let LIKELY_CARD_FORMAT = "Likely Card : %@".localized
    
    /*==========================================================================
     
     =========================================================================*/
//    private var displayedNTAG: LNTAG215?
    private var displayedNTAG = LNTAG215()
    private var isCardDetected = false
    private var openURLButtonState: Bool {
        if autoOpenURLCheck.isOn {
            return false
        } else {
            if displayedNTAG.cardData == nil {
                return false
            } else {
                if displayedNTAG.prefix.contains("http") {
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
            let writeStr = str.replacingOccurrences(of: LNTAG215.prefixString(of: prefix), with: "")
            
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
    private var isVerifyState = false
    
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
        displayedNTAG.delegate = self
        
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
        soundPopup.addItems(withTitles: NSSound.soundList)
        soundPopup.selectItem(at: Int.load(forKey: READ_COMPLETE_SOUND_SAVE_KEY))

        autoOpenURLCheck.isOn = Bool.load(forKey: OPEN_URL_AUTOMATICALLY_SAVE_KEY)


        if autoReadingCheck.isOn {
            readButton.isEnabled = false
        }
        
        Timer.scheduledTimer(withTimeInterval: AUTO_READING_INTERVAL, repeats: true) { [self] Timer in
            if autoReadingCheck.isOn {
                displayedNTAG.searchReaders()
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
        DispatchQueue.main.async { [self] in
            if let sound = NSSound(named: soundPopup.selectedItem!.title) {
                sound.play()
            }
        }
    }
}

//MARK: - action
extension ViewController: NSTextFieldDelegate {
    @IBAction func readUIDButton(_ sender: Any) {
        displayedNTAG.readUIDAsync()
    }
    @IBAction func readButton(_ sender: Any) {
//        displayedNTAG.readDataAsync()
        displayedNTAG.readUIDAsync()    //UID受信デリゲートでカードデータリードをする
    }
    @IBAction func writeButton(_ sender: Any) {
        let prefix = LNTAG215.prefix(of: writeDataField.stringValue)
        
        dprint(writeString, writeString.data(using: .utf8)!)
        displayedNTAG.writeDataAsync(prefix: prefix, payload: writeString.data(using: .utf8)!)
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
        let prefix = displayedNTAG.cardData!.prefixString
        let payload = displayedNTAG.cardData!.payloadString
        
        NSWorkspace.shared.open(URL(string: prefix + payload)!)
    }
    
    /*==========================================================================
     
     =========================================================================*/
    private func writeDataFieldDidChange() {
        let prefix = LNTAG215.prefix(of: writeDataField.stringValue)
        
        writeURLPrefixField.stringValue = LNTAG215.prefixString(of: prefix)
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

extension ViewController: LNTAG215Delegate {
    func didFinishSearchingCardReaders() {
        if displayedNTAG.cardReaderStatus == .validCard {
            if isCardDetected == false {
                isCardDetected = true
                dprint("Card Detect!")
                readButton(self)
            }
        } else {
            isCardDetected = false
        }

    }
    func didFinishReadingUID(UID: String?) {
        displayedNTAG.readDataAsync()
    }
    func didFinishReadingCardData(cardData: NTAGCardData?) {
        if isVerifyState {
            playSound()
            writeResultWork()
        } else {
            DispatchQueue.main.async { [self] in
                if cardData != nil {
                    uidField.stringValue = displayedNTAG.UID
                    
                    print(cardData!.prefix, cardData!.payloadString)
                    readURLPrefixField.stringValue = cardData!.prefixString
                    readPrefixField.stringValue = String(format: "0x%02X", cardData!.prefix)
                    readDataField.stringValue = cardData!.payloadString
                    uidField.stringValue = displayedNTAG.UID
                    playSound()
                    openURLButton.isEnabled = openURLButtonState
                    readBytesLabel.stringValue = String(format: WRITE_BYTES_FORMAT, readBytes)
                    likelyCardLabel.stringValue = String(format: LIKELY_CARD_FORMAT, LNTAG215.writableCard(for: readBytes).name)
                    
                    if autoOpenURLCheck.isOn {
                        if cardData!.prefixString.contains("http") {
                            let url = cardData!.prefixString + cardData!.payloadString
                            
                            NSWorkspace.shared.open(URL(string: url)!)
                        }
                    }
                }
            }
        }
    }
    func didFinishWritingCardData(success: Bool) {
        if !success {
            let alert = NSAlert.criticalAlert(okTitle: "OK", cancelTitle: nil, message: "Write Fail !".localized)
            
            alert.icon = NSApplication.shared.applicationIconImage
            playSound()
            alert.beginSheetModal(for: view.window!) { response in
                
            }
        } else {
            isVerifyState = true
            displayedNTAG.readDataAsync()
        }
    }
    func writeResultWork() {
        let readPayload = displayedNTAG.cardData!.payloadString
        
        isVerifyState = false
        
        DispatchQueue.main.async { [self] in
            print(writeString.unicodeScalars.map { $0.value })
            print(readPayload.unicodeScalars.map { $0.value })
            dprint(writeString, readPayload, writeString.data(using: .utf8)!.count, readPayload.data(using: .utf8)!.count)
            if readPayload == writeString {
                let alert = NSAlert.informativeAlert(okTitle: "OK", cancelTitle: nil, message: "Write successfully.".localized)
                
                alert.icon = NSApplication.shared.applicationIconImage
                alert.beginSheetModal(for: view.window!) { response in
                    
                }
            } else {
                let alert = NSAlert.criticalAlert(okTitle: "OK", cancelTitle: nil, message: "Write Fail !".localized)
                
                alert.icon = NSApplication.shared.applicationIconImage
                alert.beginSheetModal(for: view.window!) { response in
                    
                }
            }
        }
    }
}
