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

public struct NetworkServiceConstants {
    public static let RECOVERABLE_ERROR_CODES = [408, 504, 503]
    public static let HTTP_SUCCESS_CODES = 200 ... 299
    public struct Headers {
        public static let IF_MODIFIED_SINCE = "If-Modified-Since"
        public static let IF_NONE_MATCH = "If-None-Match"
        public static let LAST_MODIFIED = "Last-Modified"
        public static let ETAG = "Etag"
        public static let CONTENT_TYPE = "Content-Type"
    }

    public struct HeaderValues {
        public static let CONTENT_TYPE_URL_ENCODED = "application/x-www-form-urlencoded"
    }

    public static let RECOVERABLE_URL_ERROR_CODES: [URLError.Code] = [
        URLError.timedOut,
        URLError.cannotConnectToHost,
        URLError.networkConnectionLost,
        URLError.notConnectedToInternet,
        URLError.dataNotAllowed
    ]

}
