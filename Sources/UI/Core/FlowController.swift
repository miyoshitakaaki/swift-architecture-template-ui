import Combine
import UIKit
import Utility

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public enum ShowType {
    case modal(
        navigation: NavigationController,
        modalPresentationStyle: UIModalPresentationStyle? = nil
    ),
        push
}

public protocol FlowBase {
    associatedtype T
    associatedtype Child

    var root: Child { get }
    var navigation: T { get }
    var alertMessageAlignment: NSTextAlignment? { get }
    var alertTintColor: UIColor? { get }

    init(
        navigation: T,
        root: Child,
        alertMessageAlignment: NSTextAlignment?,
        alertTintColor: UIColor?
    )
}

open class BaseFlow<Child>: FlowBase {
    public let root: Child
    public let navigation: NavigationController
    public let alertMessageAlignment: NSTextAlignment?
    public let alertTintColor: UIColor?

    public required init(
        navigation: NavigationController,
        root: Child,
        alertMessageAlignment: NSTextAlignment?,
        alertTintColor: UIColor?
    ) {
        self.navigation = navigation
        self.root = root
        self.alertMessageAlignment = alertMessageAlignment
        self.alertTintColor = alertTintColor
    }
}

public protocol FlowController: UIViewController, FlowBase, AlertPresentable {
    var skipViewDidLoadStart: Bool { get }
    var delegate: FlowDelegate? { get set }
    var cancellables: Set<AnyCancellable> { get set }
    var childProvider: (Child) -> UIViewController { get }
    var asyncChildProvider: ((Child) -> AnyPublisher<UIViewController, Never>)? { get }
    func clear()
}

public extension FlowController {
    var skipViewDidLoadStart: Bool { false }

    var childProvider: (Child) -> UIViewController {{ _ in
        UIViewController(nibName: nil, bundle: nil)
    }}

    var asyncChildProvider: ((Child) -> AnyPublisher<UIViewController, Never>)? { nil }

    func showApplication(url: String) {
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

public extension FlowController where T == NavigationController {
    func clear() {
        self.navigation.viewControllers = []
    }

    var rootViewController: UIViewController? {
        self.navigation.viewControllers.first
    }

    func show(_ child: Child, root: Bool = false) {
        if let provider = self.asyncChildProvider {
            provider(child)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] vc in

                    guard let self else { return }

                    if root {
                        if self.navigation.viewControllers.isEmpty {
                            self.add(self.navigation)
                            self.navigation.viewControllers = [vc]
                        } else {
                            self.add(vc)
                        }
                    } else {
                        self.navigation.pushViewController(vc, animated: true)
                    }
                }.store(in: &self.cancellables)
        } else {
            let vc = self.childProvider(child)

            if root {
                if self.navigation.viewControllers.isEmpty {
                    add(self.navigation)
                    self.navigation.viewControllers = [vc]
                } else {
                    add(vc)
                }
            } else {
                self.navigation.pushViewController(vc, animated: true)
            }
        }
    }

    func start<F: FlowController>(
        flowType: F.Type,
        root: F.Child,
        delegate: FlowDelegate,
        showType: ShowType,
        alertMessageAlignment: NSTextAlignment?,
        alertTintColor: UIColor?
    ) where F.T == NavigationController {
        switch showType {
        case let .modal(navigation, style):
            let flow = F(
                navigation: navigation,
                root: root,
                alertMessageAlignment: alertMessageAlignment,
                alertTintColor: alertTintColor
            )

            if let style = style {
                flow.modalPresentationStyle = style
            }

            flow.delegate = delegate
            flow.presentationController?.delegate = self
                .rootViewController as? UIAdaptivePresentationControllerDelegate
            flow.navigation.presentationController?.delegate = self
                .rootViewController as? UIAdaptivePresentationControllerDelegate
            self.present(flow, animated: true)

        case .push:
            let flow = F(
                navigation: self.navigation,
                root: root,
                alertMessageAlignment: alertMessageAlignment,
                alertTintColor: alertTintColor
            )
            flow.delegate = delegate
            self.navigation.pushViewController(flow, animated: true)
        }
    }

    func show(error: AppError, okAction: ((UIAlertAction) -> Void)? = nil) {
        switch error {
        case let .normal(title, message):

            if let okAction {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor,
                    action: okAction
                )
            } else {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { [weak self] _ in
                    guard let self else { return }

                    if self.navigation.viewControllers.count == 1 {
                        self.dismiss(animated: true)
                    } else {
                        _ = self.navigation.popViewController(animated: true)
                    }
                }
            }

        case let .auth(title, message):

            if let okAction {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor,
                    action: okAction
                )
            } else {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { [weak self] _ in

                    guard let self else { return }

                    self.clear()

                    self.dismiss(animated: true) {
                        self.delegate?.didFinished()
                    }
                }
            }

        case let .notice(title, message):
            if let okAction {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor,
                    action: okAction
                )
            } else {
                self.present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { _ in }
            }

        case .none:
            break
        }
    }
}

public extension FlowController where T == TabBarController {
    func clear() {
        self.navigation.viewControllers = []
    }

    var rootViewController: UIViewController? {
        self.navigation.viewControllers?.first
    }

    func show(error: AppError) {
        switch error {
        case let .normal(title, message):
            self
                .present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { _ in }

        case let .auth(title, message):
            self
                .present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { [weak self] _ in

                    guard let self else { return }

                    self.clear()

                    self.dismiss(animated: true) {
                        self.delegate?.didFinished()
                    }
                }

        case let .notice(title, message):
            self
                .present(
                    title: title,
                    message: message,
                    messageAlignment: alertMessageAlignment,
                    tintColor: alertTintColor
                ) { _ in }

        case .none:
            break
        }
    }
}
