//
//  LNTAG215.swift
//  NativeNFC
//
//  Created by 大川 博 on 2026/03/24.
//

import Foundation
import CryptoTokenKit

protocol LNTAG215Delegate {
    func didFinishSearchingCardReaders()
    func didFinishReadingUID(UID: String?)
    func didFinishReadingCardData(cardData: NTAGCardData?)
    func didFinishWritingCardData(success: Bool)
}

public enum NTAGCardType {
    case NTAG213
    case NTAG215
    case NTAG216
    case none
    
    var name: String {
        switch self {
            case .NTAG213: return "NTAG213"
            case .NTAG215: return "NTAG215"
            case .NTAG216: return "NTAG215"
            case .none: return "NONE"
        }
    }
    var capacity: Int {
        switch self {
            case .NTAG213: return 144
            case .NTAG215: return 504
            case .NTAG216: return 888
            case .none: return 0
        }
    }
}
public struct NTAGCardData {
    private var rawData = Data()
    public var TLVType = 0x03
    public var NDEFLength = 0
    public var NDEFRecordHeader = 0
    public var typeLength = 0
    public var payloadLength = 0
    public var typeField = 0
    public var prefix = 0
    
    /*==========================================================================
     
     =========================================================================*/
    public var prefixString: String {
        LNTAG215.prefixString(of: prefix)
    }
    public var payload: Data { return rawData[7 ..< 7 + payloadLength - 1] }
    public var payloadString: String {
        guard rawData.count > 0 else { return "" }
        
        if let result = String(data: payload, encoding: .utf8) {
            return result
        } else {
            return ""
        }
    }
    
    /*==========================================================================
     
     =========================================================================*/
    init(readData: Data) {
        rawData = readData
        TLVType = Int(readData[0])
        NDEFLength = Int(readData[1])
        NDEFRecordHeader = Int(readData[2])
        typeLength = Int(readData[3])
        payloadLength = Int(readData[4])
        typeField = Int(readData[5])
        prefix = Int(readData[6])
    }
    
}

public enum SmartCardReaderStatus: String {
    case missing = "missing"
    case empty = "empty"
    case probing = "probing"
    case muteCard = "muteCard"
    case validCard = "validCard"
    case unknown = "unknown"
}

public struct SmartCardReaderInfo {
    let name: String
//    let status: String
    let status: SmartCardReaderStatus
    let atr: String
    let canWrite: Bool
}

fileprivate let RAW_PREFIX_LIST = [
    /* 0x00 : */"(no prefix）",
    /* 0x01 : */"http://www.",
    /* 0x02 : */"https://www.",
    /* 0x03 : */"http://",
    /* 0x04 : */"https://",
    /* 0x05 : */"tel:",
    /* 0x06 : */"mailto:",
    /* 0x07 : */"ftp://anonymous:anonymous@",
    /* 0x08 : */"ftp://ftp.",
    /* 0x09 : */"ftps://",
    /* 0x0A : */"sftp://",
    /* 0x0B : */"smb://",
    /* 0x0C : */"nfs://",
    /* 0x0D : */"ftp://",
    /* 0x0E : */"dav://",
    /* 0x0F : */"news:",
    /* 0x10 : */"telnet://",
    /* 0x11 : */"imap:",
    /* 0x12 : */"rtsp://",
    /* 0x13 : */"urn:",
    /* 0x14 : */"pop:",
    /* 0x15 : */"sip:",
    /* 0x16 : */"sips:",
    /* 0x17 : */"tftp:",
    /* 0x18 : */"btspp://",
    /* 0x19 : */"btl2cap://",
    /* 0x1A : */"btgoep://",
    /* 0x1B : */"tcpobex://",
    /* 0x1C : */"irdaobex://",
    /* 0x1D : */"file://",
    /* 0x1E : */"urn:epc:id:",
    /* 0x1F : */"urn:epc:tag:",
    /* 0x20 : */"urn:epc:pat:",
    /* 0x21 : */"urn:epc:raw:",
    /* 0x22 : */"urn:epc:",
    /* 0x23 : */"urn:nfc:",
]

class LNTAG215: NSObject {
    private static let didFinishSearchingCardReadersNotification = Notification.Name("LNTAG215.didFinishSearchingCardReadersNotification")
    private static let didFinishReadingUIDNotification = Notification.Name("LNTAG215.didFinishReadingUIDNotification")
    private static let didFinishReadingCardDataNotification = Notification.Name("LNTAG215.didFinishReadingCardDataNotification")
    private static let didFinishWritingCardDataNotification = Notification.Name("LNTAG215.didFinishWritingCardDataNotification")

    private let didFinishSearchingCardReadersNotification = Notification.Name("didFinishSearchingCardReadersNotification")
    private let didFinishReadingUIDNotification = Notification.Name("didFinishReadingUIDNotification")
    private let didFinishReadingCardDataNotification = Notification.Name("didFinishReadingCardDataNotification")
    private let didFinishWritingCardDataNotification = Notification.Name("didFinishWritingCardDataNotification")

    /*==========================================================================
     
     =========================================================================*/
    private static let localizer = LLocalizer(stringFileName: "LNTAG215")
    private static var PREFIX_LIST: [String] {  //localized
        return RAW_PREFIX_LIST.map {localizer.localize($0)}
    }

    /*==========================================================================
     
     =========================================================================*/
    
    private var readers = [SmartCardReaderInfo]()
    public var cardReaderStatus: SmartCardReaderStatus {
        if let reader = readers.first {
            return reader.status
        } else {
            return .missing
        }
    }
    public var delegate: Any?

    private(set) var cardData: NTAGCardData?
    private(set) var UID = ""

    public var prefix: String {
        guard cardData != nil else { return "" }
        
        if cardData!.prefix < LNTAG215.PREFIX_LIST.count {
            return LNTAG215.PREFIX_LIST[cardData!.prefix]
        } else {
            return ""
        }
    }
    public static var prefixes: [String] {
        var result = [String]()
        
        for p in RAW_PREFIX_LIST {
            result.append(p)
        }
        return result
    }

    /*==========================================================================
     
     =========================================================================*/
    public var isCardReaderConnected: Bool {
        return readers.count > 0
    }
    
    /*==========================================================================
     
     =========================================================================*/
    ///インスタンス生成時にUIDと書き込まれているデータを取得します
    override init() {
        super.init()
//        searchReaders()
    }
}

//MARK: - read from card reader
extension LNTAG215 {
    /*==========================================================================
     public hardware access
     =========================================================================*/
    public func searchReaders() {
        checkReaders { [self] infos in
            readers = infos
            for info in infos {
                print("Name: \(info.name), Status: \(info.status.rawValue), ATR: \(info.atr), CanWrite: \(info.canWrite)")
            }
            NotificationCenter.default.post(name: didFinishSearchingCardReadersNotification, object: self)
            (delegate as? LNTAG215Delegate)?.didFinishSearchingCardReaders()
        }
    }
    public func readUIDAsync() {
        readUID { [self] uid in
            let result = uid
            
            if result != nil {
                UID = result!
            }
            (delegate as? LNTAG215Delegate)?.didFinishReadingUID(UID: result)
        }
    }
    public func readDataAsync() {
        readData { [self] data in
//            dprint(String(data))
            cardData = NTAGCardData(readData: data)
//            dprint(cardData?.payloadString)
            (delegate as? LNTAG215Delegate)?.didFinishReadingCardData(cardData: cardData)
        }
    }
    public func writeDataAsync(prefix: Int, payload: Data) {
//        dprint(String(data: payload, encoding: .utf8)!)
        writeData(prefix: prefix, payload: payload) { [self] success in
            (delegate as? LNTAG215Delegate)?.didFinishWritingCardData(success: success)
        }
    }
    /// 接続されているリーダー情報を取得する非同期メソッド
    /// - Parameter completion: 結果の配列を返すクロージャー
    /*==========================================================================
     ハードウェアの非同期アクセス
     =========================================================================*/
    private func checkReaders(completion: @escaping ([SmartCardReaderInfo]) -> Void) {
        guard let manager = TKSmartCardSlotManager.default else {
            completion([]) // マネージャーなしなら空配列
            return
        }
        
        let slotNames = manager.slotNames
        guard !slotNames.isEmpty else {
            completion([]) // リーダーなしなら空配列
            return
        }
        
        var results: [SmartCardReaderInfo] = []
        let group = DispatchGroup()
        
        for name in slotNames {
            group.enter()
            manager.getSlot(withName: name) { slot in
                var status = "unknown"
                var atrString = ""
                var canWrite = false
                
                if let slot = slot {
                    switch slot.state {
                        case .missing: status = "missing"
                        case .empty: status = "empty"
                        case .probing: status = "probing"
                        case .muteCard: status = "muteCard"
                        case .validCard: status = "validCard"
                        @unknown default: status = "unknown"
                    }
                    
                    if let atrObject = slot.atr {
                        let atrBytes = atrObject.bytes
                        atrString = atrBytes.map { String(format: "%02X", $0) }.joined()
                        canWrite = (slot.state == .validCard)
                    }
                }
                
                let info = SmartCardReaderInfo(name: name,
                                               status: SmartCardReaderStatus(rawValue: status)!,
                                               atr: atrString,
                                               canWrite: canWrite)
                results.append(info)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    private func readUID(completion: @escaping (String?) -> Void) {
        guard let manager = TKSmartCardSlotManager.default else {
            completion(nil)
            return
        }
        
        guard let slotName = manager.slotNames.first else {
            completion(nil)
            return
        }
        
        manager.getSlot(withName: slotName) { slot in
            guard let card = slot?.makeSmartCard() else {
                completion(nil)
                return
            }
            
            card.beginSession { success, error in
                guard success else {
                    completion(nil)
                    return
                }
                
                let command = Data([0xFF, 0xCA, 0x00, 0x00, 0x00])
                
                card.transmit(command) { response, error in
                    if let data = response {
                        let sw1 = data[data.count - 2]
                        let sw2 = data[data.count - 1]
                        let uid = data[0 ..< data.count - 2]
                        let uidStr = uid.map { String(format: "%02X", $0) }.joined()
//                        dprint(String(format: "SW1:0x%02X, SW2:0x%02X, UID:%@", sw1, sw2, uidStr))
                        completion(uidStr)
                    } else {
                        completion(nil)
                    }
                    //                    if let data = response, data.count >= 2 {
                    //                        let uid = data.prefix(data.count - 2)
                    //                        let result = uid.map { String(format: "%02X", $0) }.joined()
                    //                        completion(result)
                    //                    } else {
                    //                        completion(nil)
                    //                    }
                }
            }
        }
    }
    private func readData(completion: @escaping (Data) -> Void) {
        guard let manager = TKSmartCardSlotManager.default,
              let slotName = manager.slotNames.first else { return }
        
        manager.getSlot(withName: slotName) { slot in
            guard let card = slot?.makeSmartCard() else { return }
            
            card.beginSession { success, error in
                guard success else { return }
                
                var fullData = Data()
                var currentBlock = UInt8(0x04)
                let maxBlock = UInt8(200)   //適当な数値、完了は0xfeをチェックしているので大丈夫
                
                func readNextBlock() {
                    let readCmd = Data([0xFF, 0xB0, 0x00, currentBlock, 0x10])
                    card.transmit(readCmd) { res, _ in
                        if let blockData = res, blockData.count > 2 {
                            fullData.append(blockData.prefix(blockData.count - 2))
                            
                            if blockData.contains(0xFE) || currentBlock >= maxBlock {
                                // 読み取り完了 → completionで返す
                                completion(fullData)
                            } else {
                                currentBlock += 4
                                readNextBlock()
                            }
                        } else {
                            completion(fullData)
                        }
                    }
                }
                
                readNextBlock()
            }
        }
    }
    private func writeData(prefix: Int, payload: Data, completion: @escaping (Bool) -> Void) {
//        dprint(String(data: payload, encoding: .utf8))
        guard let manager = TKSmartCardSlotManager.default,
              let slotName = manager.slotNames.first else {
            completion(false)
            return
        }
        
        manager.getSlot(withName: slotName) { slot in
            guard let card = slot?.makeSmartCard() else {
                completion(false)
                return
            }
            
            card.beginSession { success, error in
                guard success else {
                    completion(false)
                    return
                }
                
                // NDEFデータを作成 (TLV+URLレコード+終端)
                var ndefData = Data()
                let payloadLength = payload.count + 1
                let ndefMessageLength = 1 + 1 + 1 + 1 + payloadLength // D1 + TypeLength + PayloadLength + Type('U') + prefix+payload
                
                ndefData.append(0x03) // TLV Tag
                ndefData.append(UInt8(ndefMessageLength)) //
                ndefData.append(0xD1) // Record Header (MB=1, ME=1, SR=1, TNF=0x01)
                ndefData.append(0x01) // Type Length
                ndefData.append(UInt8(payloadLength)) // Payload Length
                ndefData.append(0x55) // Type 'U' (URI)
                ndefData.append(UInt8(prefix)) // Prefixコード
                ndefData.append(payload) // URL本体
                ndefData.append(0xFE) // Terminator TLV
                
                // 4バイト単位にパディング
                while ndefData.count % 4 != 0 { ndefData.append(0x00) }
                
                // 書き込み
                let blockSize = 4
                var currentOffset = 0
                let startBlock: UInt8 = 0x04 // NDEF開始ブロック
                
                func writeNextBlock() {
                    if currentOffset >= ndefData.count {
                        completion(true)
                        return
                    }
                    
                    let end = min(currentOffset + blockSize, ndefData.count)
                    let chunk = ndefData.subdata(in: currentOffset..<end)
                    let blockNum = startBlock + UInt8(currentOffset / blockSize)
                    
                    // UPDATE BINARY コマンド
                    var writeCmd = Data([0xFF, 0xD6, 0x00, blockNum, UInt8(blockSize)])
                    writeCmd.append(chunk)
                    
                    card.transmit(writeCmd) { _, error in
                        if let _ = error {
                            completion(false)
                            return
                        }
                        currentOffset += blockSize
                        writeNextBlock()
                    }
                }
                
                writeNextBlock()

            }
        }
    }

    /*==========================================================================
     utilities
     =========================================================================*/
    public static func prefixString(of prefix: Int) -> String {
        return PREFIX_LIST[prefix]
    }
    public static func prefix(of url: String) -> Int {
        for (index, str) in PREFIX_LIST.enumerated() {
            if url.hasPrefix(str) {
                return index
            }
        }
        return 0
    }
    public static func writableCard(for byteCount: Int) -> NTAGCardType {
        if byteCount < NTAGCardType.NTAG213.capacity {
            return .NTAG213
        } else if byteCount < NTAGCardType.NTAG213.capacity {
            return .NTAG215
        } else if byteCount < NTAGCardType.NTAG216.capacity {
            return .NTAG216
        } else {
            return .none
        }
    }

}
