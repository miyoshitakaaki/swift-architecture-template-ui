import UIKit
import Utility

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public enum ShowType {
    case modal(navigation: NavigationController), push
}

public protocol FlowController: UIViewController, AlertPresentable {
    associatedtype T
    associatedtype Child
    associatedtype Flow
    var alertMessageAlignment: NSTextAlignment? { get }
    var alertTintColor: UIColor? { get }
    var navigation: T { get }
    var delegate: FlowDelegate? { get set }
    var childProvider: (Child) -> UIViewController { get }
    var flowProvider: (Flow) -> any FlowController { get }
    func start()
    func clear()
    init(navigation: T, root: Child)
}

public extension FlowController {
    var childProvider: (Child) -> UIViewController {{ _ in
        UIViewController(nibName: nil, bundle: nil)
    }}

    var flowProvider: (Flow) -> any FlowController { fatalError() }

    func show(
        navigation: NavigationController,
        vc: UIViewController
    ) {
        if navigation.viewControllers.isEmpty {
            add(navigation)
            navigation.viewControllers = [vc]
        } else {
            add(vc)
        }
    }

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
        let vc = self.childProvider(child)

        if root {
            self.show(navigation: self.navigation, vc: vc)
        } else {
            self.navigation.pushViewController(vc, animated: true)
        }
    }

    func start<F: FlowController>(
        flowType: F.Type,
        root: F.Child,
        delegate: FlowDelegate,
        showType: ShowType
    ) where F.T == NavigationController {
        switch showType {
        case let .modal(navigation):
            let flow = F(navigation: navigation, root: root)
            flow.delegate = delegate
            flow.presentationController?.delegate = self
                .rootViewController as? UIAdaptivePresentationControllerDelegate
            flow.navigation.presentationController?.delegate = self
                .rootViewController as? UIAdaptivePresentationControllerDelegate
            self.present(flow, animated: true)

        case .push:
            let flow = F(navigation: self.navigation, root: root)
            flow.delegate = delegate
            self.navigation.pushViewController(flow, animated: true)
        }
    }

    func start(_ flow: Flow, present: Bool) {
        let flow = self.flowProvider(flow)
        if present {
            self.present(flow, animated: true)
        } else {
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
