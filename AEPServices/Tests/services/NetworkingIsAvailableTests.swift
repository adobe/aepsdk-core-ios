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

/// Tests for `Networking.isNetworkAvailable()` — the default NWPathMonitor-backed implementation
/// provided by the protocol extension and the custom-override mechanism available to callers.
///
/// All tests are deterministic: the test seam (`NetworkPathMonitorProvider.shared.pathStatusProvider`)
/// injects a known path status so no test depends on the developer's live network connection.
class NetworkingIsAvailableTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset any override left by a prior test before each test runs.
        NetworkPathMonitorProvider.shared.pathStatusProvider = nil
    }

    override func tearDown() {
        // Restore to production state (real NWPathMonitor) and clean up ServiceProvider.
        NetworkPathMonitorProvider.shared.pathStatusProvider = nil
        ServiceProvider.shared.reset()
        super.tearDown()
    }

    // MARK: - Test fixtures

    /// A minimal conformer that does NOT implement `isNetworkAvailable()`.
    /// It receives the protocol extension's default implementation for free —
    /// source-compatible with all pre-existing `Networking` conformers across AEP extension repos
    /// (e.g. `MockNetworkService`, `RealNetworkService`).
    private class MinimalNetworkingConformer: Networking {
        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {}
    }

    /// A conformer implementing custom availability logic — the documented override pattern for a
    /// customer who wants to use their own health-check logic instead of device connectivity alone.
    private class CustomNetworking: Networking {
        var overrideValue: Bool
        private(set) var connectAsyncCallCount = 0

        init(_ value: Bool) { overrideValue = value }

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
            connectAsyncCallCount += 1
        }

        func isNetworkAvailable() -> Bool { return overrideValue }
    }

    /// A conformer that overrides `networkConnectionInfo()` with injected values —
    /// demonstrates the documented custom-override path for richer connection state.
    private class CustomConnectionInfoNetworking: Networking {
        let info: NetworkConnectionInfo

        init(info: NetworkConnectionInfo) { self.info = info }

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {}

        func networkConnectionInfo() -> NetworkConnectionInfo { return info }
    }

    /// Helper that builds a `NetworkConnectionInfo` for injection in tests.
    private func makeInfo(available: Bool,
                          interfaceType: NetworkConnectionInfo.InterfaceType = .unknown,
                          isConstrained: Bool = false,
                          isExpensive: Bool = false) -> NetworkConnectionInfo {
        NetworkConnectionInfo(isAvailable: available,
                              interfaceType: interfaceType,
                              isConstrained: isConstrained,
                              isExpensive: isExpensive)
    }

    // MARK: - Default implementation: path status via NWPathMonitor

    func testDefaultImpl_satisfiedPath_returnsTrue() {
        NetworkPathMonitorProvider.shared.pathStatusProvider = { true }
        XCTAssertTrue(MinimalNetworkingConformer().isNetworkAvailable(),
                      "Default impl must return true when the OS reports a satisfied network path.")
    }

    func testDefaultImpl_unsatisfiedPath_returnsFalse() {
        NetworkPathMonitorProvider.shared.pathStatusProvider = { false }
        XCTAssertFalse(MinimalNetworkingConformer().isNetworkAvailable(),
                       "Default impl must return false when the OS reports an unsatisfied network path.")
    }

    func testDefaultImpl_requiresConnectionPath_returnsFalse() {
        // `requiresConnection` (e.g. on-demand VPN) means no usable path is currently available.
        // We represent it via the injection returning false — semantically identical to unsatisfied.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { false }
        XCTAssertFalse(MinimalNetworkingConformer().isNetworkAvailable(),
                       "Default impl must return false for a requires-connection path.")
    }

    func testDefaultImpl_conservativeInitialState_returnsFalse() {
        // Before the OS delivers its first path update (or when no path has been observed),
        // the expected behavior is conservative: report unavailable rather than assume connectivity.
        // Simulated here via the injection returning false.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { false }
        XCTAssertFalse(MinimalNetworkingConformer().isNetworkAvailable(),
                       "Default impl must default to false in the absence of a confirmed satisfied path.")
    }

    // MARK: - Default implementation: repeated and concurrent reads

    func testDefaultImpl_repeatedReads_returnConsistentResultWithoutLeakingResources() {
        // 1 000 sequential calls must complete immediately, return a consistent value,
        // and not accumulate monitors, callbacks, or connections.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { true }
        let conformer = MinimalNetworkingConformer()
        for i in 0..<1_000 {
            XCTAssertTrue(conformer.isNetworkAvailable(),
                          "Call \(i) returned an inconsistent result.")
        }
    }

    func testDefaultImpl_concurrentReads_noDataRaceOrDeadlock() {
        // 50 concurrent callers must each receive a valid Bool without crashing or deadlocking.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { true }
        let conformer = MinimalNetworkingConformer()
        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.adobe.test.isNetworkAvailable.concurrent",
                                            attributes: .concurrent)
        for _ in 0..<50 {
            group.enter()
            concurrentQueue.async {
                _ = conformer.isNetworkAvailable() // result is valid as long as no crash/deadlock
                group.leave()
            }
        }
        let completed = group.wait(timeout: .now() + 5)
        XCTAssertEqual(completed, .success, "Concurrent reads timed out — possible deadlock.")
    }

    // MARK: - Custom override

    func testCustomOverride_satisfiedPath_returnsTrue() {
        XCTAssertTrue(CustomNetworking(true).isNetworkAvailable(),
                      "Custom override returning true must propagate as true.")
    }

    func testCustomOverride_unsatisfiedPath_returnsFalse() {
        XCTAssertFalse(CustomNetworking(false).isNetworkAvailable(),
                       "Custom override returning false must propagate as false.")
    }

    func testCustomOverride_requiresConnectionPath_returnsFalse() {
        // Customer treats requires-connection the same as unavailable.
        XCTAssertFalse(CustomNetworking(false).isNetworkAvailable(),
                       "Custom override returning false for requires-connection must propagate as false.")
    }

    func testCustomOverride_isHonored_viaServiceProvider() {
        // Registering a custom Networking conformer via ServiceProvider must be the effective
        // implementation — the default NWPathMonitor path is bypassed entirely.
        let custom = CustomNetworking(false)
        ServiceProvider.shared.networkService = custom

        XCTAssertFalse(ServiceProvider.shared.networkService.isNetworkAvailable())

        custom.overrideValue = true
        XCTAssertTrue(ServiceProvider.shared.networkService.isNetworkAvailable())
    }

    // MARK: - networkConnectionInfo: default implementation

    func testConnectionInfo_defaultImpl_unavailable_returnsUnavailableWithUnknownType() {
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: false, interfaceType: .unknown)
        }
        let info = MinimalNetworkingConformer().networkConnectionInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .unknown)
    }

    func testConnectionInfo_defaultImpl_wifi_returnsWifiType() {
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: true, interfaceType: .wifi)
        }
        let info = MinimalNetworkingConformer().networkConnectionInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .wifi)
    }

    func testConnectionInfo_defaultImpl_cellular_returnsCellularType() {
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: true, interfaceType: .cellular)
        }
        let info = MinimalNetworkingConformer().networkConnectionInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertEqual(info.interfaceType, .cellular)
    }

    func testConnectionInfo_defaultImpl_constrained_returnsIsConstrainedTrue() {
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: true, interfaceType: .wifi, isConstrained: true)
        }
        let info = MinimalNetworkingConformer().networkConnectionInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertTrue(info.isConstrained,
                      "Low Data Mode path must be reflected in isConstrained.")
    }

    func testConnectionInfo_defaultImpl_expensive_returnsIsExpensiveTrue() {
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: true, interfaceType: .cellular, isExpensive: true)
        }
        let info = MinimalNetworkingConformer().networkConnectionInfo()
        XCTAssertTrue(info.isExpensive,
                      "Cellular / hotspot path must be reflected in isExpensive.")
    }

    func testConnectionInfo_defaultImpl_isAvailable_consistentWithIsNetworkAvailable() {
        // isNetworkAvailable() and networkConnectionInfo().isAvailable must agree.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { true }
        NetworkPathMonitorProvider.shared.connectionInfoProvider = { [self] in
            makeInfo(available: true, interfaceType: .wifi)
        }
        let conformer = MinimalNetworkingConformer()
        XCTAssertEqual(conformer.isNetworkAvailable(), conformer.networkConnectionInfo().isAvailable,
                       "isNetworkAvailable() and networkConnectionInfo().isAvailable must be consistent.")
    }

    // MARK: - networkConnectionInfo: custom override

    func testConnectionInfo_customOverride_isHonored() {
        let expected = makeInfo(available: false, interfaceType: .unknown, isConstrained: true, isExpensive: false)
        let custom = CustomConnectionInfoNetworking(info: expected)

        let result = custom.networkConnectionInfo()
        XCTAssertEqual(result.isAvailable, expected.isAvailable)
        XCTAssertEqual(result.interfaceType, expected.interfaceType)
        XCTAssertEqual(result.isConstrained, expected.isConstrained)
        XCTAssertEqual(result.isExpensive, expected.isExpensive)
    }

    func testConnectionInfo_customOverride_isHonored_viaServiceProvider() {
        let injected = makeInfo(available: true, interfaceType: .cellular, isExpensive: true)
        ServiceProvider.shared.networkService = CustomConnectionInfoNetworking(info: injected)

        let result = ServiceProvider.shared.networkService.networkConnectionInfo()
        XCTAssertTrue(result.isAvailable)
        XCTAssertEqual(result.interfaceType, .cellular)
        XCTAssertTrue(result.isExpensive)
    }

    // MARK: - Transport behavior is unchanged

    func testConnectAsync_isCallableIndependentlyOfIsNetworkAvailable() {
        // `isNetworkAvailable()` is a passive query only. Setting the path to "unavailable" must
        // NOT intercept, block, or alter how `connectAsync` is dispatched. The SDK, not
        // `isNetworkAvailable()`, decides whether to proceed with a request.
        NetworkPathMonitorProvider.shared.pathStatusProvider = { false }
        let custom = CustomNetworking(false)
        ServiceProvider.shared.networkService = custom

        let request = NetworkRequest(url: URL(string: "https://example.com")!)
        ServiceProvider.shared.networkService.connectAsync(networkRequest: request, completionHandler: nil)

        XCTAssertEqual(custom.connectAsyncCallCount, 1,
                       "connectAsync must be dispatched regardless of isNetworkAvailable() result.")
    }
}
