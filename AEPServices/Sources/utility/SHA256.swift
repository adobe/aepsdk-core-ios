/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import Foundation
import CommonCrypto

// Ref: https://stackoverflow.com/questions/25388747/sha256-in-swift
public struct SHA256 {
    
    /// Hashes `str` with SHA256
    /// - Parameter str: string to be hash
    /// - Returns: the hashed string
    public static func hash(_ str: String?) -> String? {
        guard let str = str else { return nil }
        if str.isEmpty {
            return ""
        }

        if let stringData = str.data(using: .utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }

        return nil
    }
    
    private static func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private static func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
}
