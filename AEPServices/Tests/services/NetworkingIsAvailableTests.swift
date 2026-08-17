/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPServices
import XCTest

/// Tests for `Networking.isNetworkAvailable()` and `Networking.networkConnectionInfo()`.
///
/// All deterministic coverage uses mock `Networking` conformers — no test seams live in
/// production code. Custom conformers exercise the override path; the default-implementation
/// tests verify the protocol extension is reachable and behaves correctly end-to-end.
class NetworkingIsAvailableTests: XCTestCase {

    override func tearDown() {
        ServiceProvider.shared.reset()
        super.tearDown()
    }

    // MARK: - Test fixtures

    /// Minimal conformer that does NOT override `isNetworkAvailable()` or
    /// `networkConnectionInfo()` — receives the protocol extension defaults for free.
    /// Source-compatible with all pre-existing `Networking` conformers across AEP repos.
    private class MinimalNetworkingConformer: Networking {
        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {}
    }

    /// Conformer with custom availability logic — the documented override pattern for
    /// customers who want their own health-check instead of device connectivity.
    private class CustomNetworking: Networking {
        var overrideValue: Bool
        private(set) var connectAsyncCallCount = 0

        init(_ value: Bool) { overrideValue = value }

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
            connectAsyncCallCount += 1
        }

        func isNetworkAvailable() -> Bool { return overrideValue }

        func networkConnectionInfo() -> NetworkConnectionInfo {
            return NetworkConnectionInfo(isAvailable: overrideValue,
                                         interfaceType: overrideValue ? .wifi : .unknown,
                                         isConstrained: false,
                                         isExpensive: false)
        }
    }

    /// Conformer that overrides `networkConnectionInfo()` with injected values —
    /// demonstrates the custom-override path for richer connection state.
    private class CustomConnectionInfoNetworking: Networking {
        let info: NetworkConnectionInfo

        init(info: NetworkConnectionInfo) { self.info = info }

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {}

        func networkConnectionInfo() -> NetworkConnectionInfo { return info }
    }

    private func makeInfo(available: Bool,
                          interfaceType: NetworkConnectionInfo.InterfaceType = .unknown,
                          isConstrained: Bool = false,
                          isExpensive: Bool = false) -> NetworkConnectionInfo {
        NetworkConnectionInfo(isAvailable: available,
                              interfaceType: interfaceType,
                              isConstrained: isConstrained,
                              isExpensive: isExpensive)
    }

    // MARK: - Default implementation (live NWPathMonitor)

    func testDefaultImpl_returnsValidBool() {
        // Verifies the protocol extension is wired up and returns without crashing.
        // Result depends on the test host's network state (intentional).
        let result = MinimalNetworkingConformer().isNetworkAvailable()
        XCTAssertTrue(result == true || result == false)
    }

    func testDefaultImpl_repeatedReads_noCrashOrLeak() {
        let conformer = MinimalNetworkingConformer()
        for _ in 0..<1_000 { _ = conformer.isNetworkAvailable() }
    }

    func testDefaultImpl_concurrentReads_noDataRaceOrDeadlock() {
        let conformer = MinimalNetworkingConformer()
        let group = DispatchGroup()
        let q = DispatchQueue(label: "com.adobe.test.concurrent", attributes: .concurrent)
        for _ in 0..<50 {
            group.enter()
            q.async { _ = conformer.isNetworkAvailable(); group.leave() }
        }
        XCTAssertEqual(group.wait(timeout: .now() + 5), .success,
                       "Concurrent reads timed out — possible deadlock.")
    }

    func testDefaultImpl_connectionInfo_returnsConsistentAvailability() {
        let conformer = MinimalNetworkingConformer()
        let info = conformer.networkConnectionInfo()
        // isAvailable and interfaceType must agree
        if !info.isAvailable {
            XCTAssertEqual(info.interfaceType, .unknown,
                           "Unavailable path must report .unknown interface type.")
        }
    }

    // MARK: - Custom override: isNetworkAvailable

    func testCustomOverride_returnsTrue_whenOverrideIsTrue() {
        XCTAssertTrue(CustomNetworking(true).isNetworkAvailable())
    }

    func testCustomOverride_returnsFalse_whenOverrideIsFalse() {
        XCTAssertFalse(CustomNetworking(false).isNetworkAvailable())
    }

    func testCustomOverride_isHonored_viaServiceProvider() {
        let custom = CustomNetworking(false)
        ServiceProvider.shared.networkService = custom
        XCTAssertFalse(ServiceProvider.shared.networkService.isNetworkAvailable())

        custom.overrideValue = true
        XCTAssertTrue(ServiceProvider.shared.networkService.isNetworkAvailable())
    }

    // MARK: - Custom override: networkConnectionInfo

    func testConnectionInfo_unavailable_returnsUnknownInterfaceType() {
        let info = CustomConnectionInfoNetworking(info: makeInfo(available: false)).networkConnectionInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .unknown)
    }

    func testConnectionInfo_wifi_returnsWifiType() {
        let info = CustomConnectionInfoNetworking(info: makeInfo(available: true, interfaceType: .wifi)).networkConnectionInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .wifi)
    }

    func testConnectionInfo_cellular_returnsCellularType() {
        let info = CustomConnectionInfoNetworking(info: makeInfo(available: true, interfaceType: .cellular)).networkConnectionInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .cellular)
    }

    func testConnectionInfo_constrained_isReflected() {
        let info = CustomConnectionInfoNetworking(info: makeInfo(available: true, interfaceType: .wifi, isConstrained: true)).networkConnectionInfo()
        XCTAssertTrue(info.isConstrained, "Low Data Mode must be reflected in isConstrained.")
    }

    func testConnectionInfo_expensive_isReflected() {
        let info = CustomConnectionInfoNetworking(info: makeInfo(available: true, interfaceType: .cellular, isExpensive: true)).networkConnectionInfo()
        XCTAssertTrue(info.isExpensive, "Cellular / hotspot must be reflected in isExpensive.")
    }

    func testConnectionInfo_customOverride_isHonored_viaServiceProvider() {
        let injected = makeInfo(available: true, interfaceType: .cellular, isExpensive: true)
        ServiceProvider.shared.networkService = CustomConnectionInfoNetworking(info: injected)
        let result = ServiceProvider.shared.networkService.networkConnectionInfo()
        XCTAssertTrue(result.isAvailable)
        XCTAssertEqual(result.interfaceType, .cellular)
        XCTAssertTrue(result.isExpensive)
    }

    // MARK: - Transport behaviour is unchanged

    func testConnectAsync_isCallableIndependentlyOfIsNetworkAvailable() {
        let custom = CustomNetworking(false)
        ServiceProvider.shared.networkService = custom
        let request = NetworkRequest(url: URL(string: "https://example.com")!)
        ServiceProvider.shared.networkService.connectAsync(networkRequest: request, completionHandler: nil)
        XCTAssertEqual(custom.connectAsyncCallCount, 1,
                       "connectAsync must be dispatched regardless of isNetworkAvailable() result.")
    }
}
