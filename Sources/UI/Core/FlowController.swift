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
        self.title = navContent.title

        if navigation.viewControllers.isEmpty {
            add(navigation)
            navigation.viewControllers = [vc]
        } else {
            add(vc)
        }
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
