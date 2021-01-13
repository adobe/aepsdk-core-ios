//
//  File.swift
//  AEPServices
//
//  Created by ravjain on 1/11/21.
//  Copyright © 2021 Adobe. All rights reserved.
//

import Foundation
import UIKit

public extension UIApplication {
    func getKeyWindow() -> UIWindow? {
        keyWindow ?? windows.first
    }
}
