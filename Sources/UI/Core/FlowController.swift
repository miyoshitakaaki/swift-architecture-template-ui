import UIKit

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public protocol FlowController: UIViewController {
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
}

public extension FlowController where T == TabBarController {
    func clear() {
        self.navigation.viewControllers = []
    }
}
