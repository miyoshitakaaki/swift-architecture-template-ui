import UIKit

public protocol FlowController: UIViewController {
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
