import UIKit
import Utility

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public protocol FlowController: UIViewController, AlertPresentable {
    associatedtype T
    var navigation: T { get }
    var delegate: FlowDelegate? { get set }
    func start()
    func clear()
}

public extension FlowController {
    func show(
        navigation: NavigationController,
        vc: UIViewController,
        navContent: NavigationContent
    ) {
        self.setupNavigationBar(content: navContent)

        if navigation.viewControllers.isEmpty {
            add(navigation)
            navigation.viewControllers = [vc]
        } else {
            add(vc)
        }
    }

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

    private func setupNavigationBar(content: NavigationContent) {
        self.navigationItem.rightBarButtonItems = content.rightNavigationItems
        self.navigationItem.leftBarButtonItems = content.leftNavigationItems

        if let title = content.title {
            self.title = title
        } else {
            self.navigationItem.titleView = UIView()
        }

        self.navigationItem.rightBarButtonItem?.tintColor = content.rightBarButtonItemTintColor
        self.navigationItem.leftBarButtonItem?.tintColor = content.leftBarButtonItemTintColor
    }
}

public extension FlowController where T == NavigationController {
    func clear() {
        self.navigation.viewControllers = []
    }

    var rootViewController: UIViewController? {
        self.navigation.viewControllers.first
    }

    func show(error: AppError, okAction: ((UIAlertAction) -> Void)? = nil) {
        switch error {
        case let .normal(title, message):

            if let okAction {
                self.present(title: title, message: message, action: okAction)
            } else {
                self.present(title: title, message: message) { [weak self] _ in
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
                self.present(title: title, message: message, action: okAction)
            } else {
                self.present(title: title, message: message) { [weak self] _ in

                    guard let self else { return }

                    self.clear()

                    self.dismiss(animated: true) {
                        self.delegate?.didFinished()
                    }
                }
            }

        case let .notice(title, message):
            if let okAction {
                self.present(title: title, message: message, action: okAction)
            } else {
                self.present(title: title, message: message) { _ in }
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
            self.present(title: title, message: message) { _ in }

        case let .auth(title, message):
            self.present(title: title, message: message) { [weak self] _ in

                guard let self else { return }

                self.clear()

                self.dismiss(animated: true) {
                    self.delegate?.didFinished()
                }
            }

        case let .notice(title, message):
            self.present(title: title, message: message) { _ in }

        case .none:
            break
        }
    }
}
