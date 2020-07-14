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

/// Type representing the state of an extension's `SharedState`
public enum SharedStateStatus {
    case set, pending, none
}

class SharedState {

    private let queue: DispatchQueue /// Allows multi-threaded access to shared state.  Reads are concurrent, Add/Updates act as barriers.
    private var head: Node?

    // MARK: Internal API
    init(_ name: String = "anonymous") {
        queue = DispatchQueue(label: "com.adobe.mobile.sharedstate(\(name))", qos: .default, attributes: .concurrent)
        head = nil
    }

    /// Sets the given version of this `SharedState` to the given data dictionary.
    /// - Parameters:
    ///   - version: The version of the `SharedState` to set (must be > any existing version)
    ///   - data: The data dictionary to set.
    internal func set(version: Int, data: [String:Any]?) {
        add(version: version, data: data, status: .set)
    }

    /// Creates a pending version of this `SharedState`, which will be resolved to a valid state at some point in the future.
    /// - Parameters:
    ///   - version: The version of the `SharedState` to to create as pending
    internal func addPending(version: Int) {
        add(version: version, data: nil, status: .pending)
    }

    /// Updates a pending version of `SharedState` to a concrete value.
    /// - Parameters:
    ///   - version: The version of the pending `SharedState` to set (must already exist)
    ///   - data: The data dictionary to set.
    internal func updatePending(version: Int, data: [String:Any]?) {
        queue.async(flags: .barrier) {
            var cur = self.head
            while let unwrapped = cur {
                if unwrapped.version == version {
                    if unwrapped.nodeStatus == .pending {
                        unwrapped.data = data
                        unwrapped.nodeStatus = .set
                    } else {
                        // log error, attempting to update a non-pending entry
                    }
                    break
                }

                cur = unwrapped.previousNode
            }
        }
    }

    /// Resolves the given version to a `SharedState` instance
    /// - Parameters:
    ///   - version: The version of the `SharedState` to retrieve
    /// - Returns
    ///     - value: The current set value for the shared state
    ///     - status: The current `SharedState.Status` of the returned state
    internal func resolve(version: Int) -> (value: [String:Any]?, status: SharedStateStatus) {
        return queue.sync {
            var cur = head
            while let unwrapped = cur {
                if unwrapped.version <= version {
                    return (unwrapped.data, unwrapped.nodeStatus)
                } else if unwrapped.previousNode == nil {
                    return (unwrapped.data, unwrapped.nodeStatus)
                }
                cur = unwrapped.previousNode
            }
            return (nil, .none)
            
        }
    }

    // MARK: Private API
    private func add(version: Int, data: [String:Any]?, status: SharedStateStatus) {
        queue.async(flags: .barrier) {
            if let unwrapped = self.head {
                if unwrapped.version < version {
                    self.head = unwrapped.append(version: version, data: data, status: status)
                } else {
                    // log error, trying to add an already existing version
                }
            } else {
                self.head = Node(version: version, data: data, status: status)
            }
        }
    }

    // MARK: Internal Class (Node definition)
    /// Node class defines a specific version of a SharedState
    private class Node {
        var nodeStatus: SharedStateStatus = .pending
        var previousNode: Node? = nil
        let version: Int
        var data: [String:Any]? = nil

        // appends a node to this node and returns the new node.
        func append(version: Int, data: [String:Any]?, status: SharedStateStatus) -> Node? {
            let newNode = Node(version: version, data: data, status: status)
            newNode.previousNode = self
            return newNode
        }

        init(version: Int, data: [String:Any]?, status: SharedStateStatus) {
            self.version = version
            self.data = data
            self.nodeStatus = status
        }
    }
}
