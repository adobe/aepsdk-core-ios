import Foundation
#if os(iOS)
import WebKit
import UIKit
#else
import TVUIKit
import SwiftUI
#endif

/// Protocol defining UI service operations
public protocol UIService {
    /// Creates a floating button with the provided delegate
    /// - Parameter listener: The delegate to handle floating button events
    /// - Returns: A floating button presentable
    func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable

    /// Creates a fullscreen message with the provided payload and delegate
    /// - Parameters:
    ///   - payload: The content to display in the fullscreen message
    ///   - listener: The delegate to handle fullscreen message events
    ///   - isLocalImageUsed: Whether the payload contains local images (iOS only)
    /// - Returns: A fullscreen message presentable
    func createFullscreenMessage(payload: Any, listener: FullscreenPresentableDelegate, isLocalImageUsed: Bool) -> FullscreenPresentable
}

/// Implementation of the UIService protocol
public class UIServiceImpl: UIService {
    public init() {}

    public func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable {
        #if os(iOS)
        return FloatingButton(listener: listener)
        #else
        return TVFloatingButton(listener: listener)
        #endif
    }

    public func createFullscreenMessage(payload: Any, listener: FullscreenPresentableDelegate, isLocalImageUsed: Bool) -> FullscreenPresentable {
        #if os(iOS)
        if let htmlString = payload as? String {
            return FullscreenMessage(payload: htmlString, listener: listener)
        }
        return FullscreenMessage(payload: "", listener: listener)
        #else
        if let swiftUIView = payload as? View {
            return FullscreenMessageNative(payload: swiftUIView, listener: listener)
        }
        return FullscreenMessageNative(payload: EmptyView(), listener: listener)
        #endif
    }
}

#if os(tvOS)
class FullscreenMessageNative: FullscreenPresentable {
    private var viewController: UIHostingController<AnyView>?
    private var listener: FullscreenPresentableDelegate?

    init(payload: View, listener: FullscreenPresentableDelegate) {
        self.listener = listener
        self.viewController = UIHostingController(rootView: AnyView(payload))
    }

    func show() {
        guard let viewController = viewController else { return }
        // Present the view controller
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true) {
                self.listener?.onShow(message: self)
            }
        }
    }

    func dismiss() {
        viewController?.dismiss(animated: true) {
            self.listener?.onDismiss(message: self)
        }
    }
}
#endif
