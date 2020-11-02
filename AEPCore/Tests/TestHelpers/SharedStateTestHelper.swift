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
@testable import AEPCore

struct SharedStateTestHelper {
    public static let DICT_KEY: String = "dictionary"
    public static let ZERO = SharedStateData(standard: [DICT_KEY: "zero"], xdm: [DICT_KEY: "zero_xdm"])
    public static let ONE = SharedStateData(standard: [DICT_KEY: "one"], xdm: [DICT_KEY: "one_xdm"])
    public static let TWO = SharedStateData(standard: [DICT_KEY: "two"], xdm: [DICT_KEY: "two_xdm"])
    public static let THREE = SharedStateData(standard: [DICT_KEY: "three"], xdm: [DICT_KEY: "three_xdm"])
    public static let FOUR = SharedStateData(standard: [DICT_KEY: "four"], xdm: [DICT_KEY: "four_xdm"])
    public static let FIVE = SharedStateData(standard: [DICT_KEY: "five"], xdm: [DICT_KEY: "five_xdm"])
    public static let TEN = SharedStateData(standard: [DICT_KEY: "ten"], xdm: [DICT_KEY: "ten_xdm"])
}
