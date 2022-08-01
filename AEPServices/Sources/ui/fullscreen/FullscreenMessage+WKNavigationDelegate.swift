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

#if os(iOS)
    import Foundation
    import WebKit

    @available(iOSApplicationExtension, unavailable)
    extension FullscreenMessage: WKNavigationDelegate {
        // MARK: WKNavigationDelegate delegate
        // default behavior is to call the decisionHandler with .allow
        // either the messagingDelegate or listener may suppress this navigation
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // notify the messagingDelegate of the url being loaded
            guard let urlToLoad = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            var navigation: WKNavigationActionPolicy = .allow

            if self.listener != nil {
                let navigateNormally = self.listener?.overrideUrlLoad(message: self, url: urlToLoad.absoluteString) ?? true

                navigation = navigateNormally ? .allow : .cancel

                if navigation == .cancel {
                    self.messagingDelegate?.urlLoaded?(urlToLoad, byMessage: self)
                }
            }

            decisionHandler(navigation)
        }

        /// Delegate method invoked when the webView navigation is complete.
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if navigation == self.loadingNavigation {
                self.listener?.webViewDidFinishInitialLoading?(webView: webView)
            }
        }
    }
#endif
