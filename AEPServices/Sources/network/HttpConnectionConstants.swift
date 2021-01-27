/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

public enum HttpConnectionConstants {
    public enum ResponseCodes {
        public static let HTTP_OK = 200
        public static let HTTP_NOT_FOUND = 404
        public static let HTTP_CLIENT_TIMEOUT = 408
        public static let HTTP_REQUESTED_RANGE_NOT_SATISFIABLE = 416
        public static let HTTP_GATEWAY_TIMEOUT = 504
        public static let HTTP_UNAVAILABLE = 503
    }

    public enum Header {
        public static let HTTP_HEADER_KEY_CONTENT_TYPE = "Content-Type"
        public static let HTTP_HEADER_KEY_ACCEPT_LANGUAGE = "Accept-Language"
        public static let HTTP_HEADER_KEY_ACCEPT = "Accept"
        public static let HTTP_HEADER_CONTENT_TYPE_JSON_APPLICATION = "application/json"
        public static let HTTP_HEADER_CONTENT_TYPE_WWW_FORM_URLENCODED = "application/x-www-form-urlencoded"
        public static let HTTP_HEADER_ACCEPT_TEXT_HTML = "text/html"
    }
}
