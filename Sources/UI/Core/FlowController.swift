import UIKit

public protocol FlowDelegate: AnyObject {
    func didFinished()
}

public protocol FlowController: UIViewController {
    var delegate: FlowDelegate? { get set }
    func start()
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
