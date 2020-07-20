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

public class MockTask: URLSessionDataTask {
    private let data: Data?
    private let urlResponse: URLResponse?
    private let _error: Error?
    var completionHandler: ((Data?, URLResponse?, Error?) -> Void)? // set by MockURLSession

    public init(data: Data?, urlResponse: URLResponse?, error: Error?) {
        self.data = data
        self.urlResponse = urlResponse
        self._error = error
    }
    
    override public func resume() {
        guard let unwrappedCompletionHandler = completionHandler else { return }
        unwrappedCompletionHandler(self.data, self.urlResponse, self._error)
    }
}
