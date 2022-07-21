import UIKit

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public protocol FlowController: UIViewController {
    associatedtype T
    var navigation: T! { get set }
    var delegate: FlowDelegate? { get set }
    func start()
    func clear()
}

public extension FlowController {
    func show(navigation: NavigationController, vc: UIViewController) {
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
