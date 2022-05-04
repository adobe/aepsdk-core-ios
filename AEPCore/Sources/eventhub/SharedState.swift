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

import AEPServices
import Foundation

/// Type representing the resolution of an extension's `SharedState`
@objc(AEPSharedStateResolution)
public enum SharedStateResolution: Int {
    // lastSet will resolve for the lastSet shared state
    // any will resolve for the last shared state indiscriminately
    case lastSet, any
}

/// Type representing the state of an extension's `SharedState`
@objc (AEPSharedStateStatus)
public enum SharedStateStatus: Int {
    case set, pending, none
}

/// Provides a construct by which an `Extension` can share its state with other `Extension`s
class SharedState {
    private let queue: DispatchQueue /// Allows multi-threaded access to shared state.  Reads are concurrent, Add/Updates act as barriers.
    private var head: Node?
    private let LOG_TAG: String
    var isEmpty: Bool {
        return queue.sync { head == nil }
    }

    // MARK: - Internal API

    init(_ name: String = "anonymous") {
        queue = DispatchQueue(label: "com.adobe.mobile.sharedstate(\(name))", qos: .default, attributes: .concurrent)
        head = nil
        LOG_TAG = "SharedState(\(name))"
    }

    /// Sets the given version of this `SharedState` to the given data dictionary.
    /// - Parameters:
    ///   - version: The version of the `SharedState` to set (must be > any existing version)
    ///   - data: The data dictionary to set.
    internal func set(version: Int, data: [String: Any]?) {
        add(version: version, data: data, status: .set)
    }

    /// Creates a pending version of this `SharedState`, which will be resolved to a valid state at some point in the future.
    /// - Parameters:
    ///   - version: The version of the `SharedState` to to create as pending
    internal func addPending(version: Int) {
        // set state to pending and use the existing (if any) shared state data as placeholder
        add(version: version, data: resolve(version: Int.max).value, status: .pending)
    }

    /// Updates a pending version of `SharedState` to a concrete value.
    /// - Parameters:
    ///   - version: The version of the pending `SharedState` to set (must already exist)
    ///   - data: The data dictionary to set.
    internal func updatePending(version: Int, data: [String: Any]?) {
        queue.async(flags: .barrier) {
            var current = self.head
            while let node = current {
                if node.version == version {
                    if node.nodeStatus == .pending {
                        node.data = data
                        node.nodeStatus = .set
                    } else {
                        Log.error(label: "\(self.LOG_TAG):\(#function)", "Attempting to update a non-pending entry.")
                    }
                    break
                }

                current = node.previousNode
            }
        }
    }

    /// Resolves the given version to a `SharedState` instance
    /// - Parameters:
    ///   - version: The version of the `SharedState` to retrieve
    /// - Returns
    ///     - value: The current set value for the shared state
    ///     - status: The current `SharedState.Status` of the returned state
    internal func resolve(version: Int) -> (value: [String: Any]?, status: SharedStateStatus) {
        return queue.sync {
            var current = self.head
            while let node = current {
                if node.version <= version {
                    return (node.data, node.nodeStatus)
                } else if node.previousNode == nil {
                    return (node.data, node.nodeStatus)
                }
                current = node.previousNode
            }
            return (nil, .none)
        }
    }

    /// Resolves the last given version which is "set" to a `SharedState` instance
    /// - Parameters:
    ///   - version: The version of the `SharedState` to retrieve
    /// - Returns: The last set value for the shared state, or .none if none is found
    internal func resolveLastSet(version: Int) -> (value: [String: Any]?, status: SharedStateStatus) {
        return queue.sync {
            var current = self.head
            while let node = current {
                if node.version <= version && node.nodeStatus == .set {
                    return (node.data, .set)
                } else if node.previousNode == nil && node.nodeStatus == .set {
                    return (node.data, .set)
                }
                current = node.previousNode
            }
            return (nil, .none)
        }
    }

    // MARK: - Private API

    private func add(version: Int, data: [String: Any]?, status: SharedStateStatus) {
        queue.async(flags: .barrier) {
            if let head = self.head {
                if head.version < version {
                    self.head = head.append(version: version, data: data, status: status)
                } else {
                    Log.debug(label: "\(self.LOG_TAG):\(#function)", "Trying to add an already existing version (\(version)), current version \(head.version).")
                }
            } else {
                self.head = Node(version: version, data: data, status: status)
            }
        }
    }

    // MARK: - Node definition (private class)

    /// Node class defines a specific version of a SharedState
    private class Node {
        var nodeStatus: SharedStateStatus = .pending
        var previousNode: Node?
        let version: Int
        var data: [String: Any]?

        /// Appends a `Node` to this `Node` and returns the new `Node`
        /// - Parameters:
        ///   - version: the version of the shared state
        ///   - data: the data for the shared state
        ///   - status: the status of the shared state
        /// - Returns: A `Node` with a reference to the previous `Node`
        func append(version: Int, data: [String: Any]?, status: SharedStateStatus) -> Node {
            let newNode = Node(version: version, data: data, status: status)
            newNode.previousNode = self
            return newNode
        }

        init(version: Int, data: [String: Any]?, status: SharedStateStatus) {
            self.version = version
            self.data = data
            nodeStatus = status
        }
    }
}
