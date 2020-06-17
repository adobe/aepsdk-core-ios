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
    func unzipItem(at sourcePath: URL, to destinationPath: URL, completion: @escaping (() -> Void))
}

struct RulesUnzipper: FileUnzipper {
    func unzipItem(at sourcePath: URL, to destinationPath: URL, completion: @escaping (() -> Void)) {
        let fileManager = FileManager()
        do {
            try fileManager.createDirectory(at: destinationPath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourcePath, to: destinationPath)
            
        } catch {
            // handle error here
            print("Extraction of Zip failed with error: \(error)")
        }
        
    }
}


