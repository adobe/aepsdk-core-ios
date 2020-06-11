//
//  CompressionService.swift
//  AEPCore
//
//  Created by Christopher Hoffman on 6/4/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation
import Compression

protocol FileUnzipper {
    func unzip(fromPath: String, to path: String, completion: @escaping (() -> Void))
}

struct RulesUnzipper: FileUnzipper {
    func unzip(fromPath: String, to destinationPath: String, completion: @escaping (() -> Void)) {
        FileManager.default.createFile(atPath: destinationPath, contents: nil, attributes: nil)
        guard let sourceFile = FileHandle(forReadingAtPath: fromPath), let destinationFile = FileHandle(forWritingAtPath: destinationPath) else {
            completion()
            return
        }
        
        let data = NSData(contentsOfFile: fromPath)
        do {

            let decompressed = try data?.decompressed(using: .lzfse)
            guard let decompressedData = decompressed as Data? else {
                return
            }
            destinationFile.write(decompressedData)
        } catch {
            print(error.localizedDescription)
        }
        
        
//        let bufferSize = 32_768
//        DispatchQueue.global(qos: .utility).async {
//            do {
//                let outputFilter = try OutputFilter(.decompress, using: .zlib) { (data: Data?) -> Void in
//                    if let data = data {
//                        destinationFile.write(data)
//                    }
//
//                }
//                let subdata: Data = sourceFile.readData(ofLength: bufferSize)
//                try outputFilter.write(subdata)
//                sourceFile.closeFile()
//                destinationFile.closeFile()
//                completion()
//            } catch {
//                // TODO: Handle error here or just complete?
//                print(error.localizedDescription)
//            }
//        }
    }
}


