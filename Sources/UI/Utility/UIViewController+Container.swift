import UIKit

public extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove(child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }

    func removeFirstChild() {
        if let firstChild = self.children.first {
            self.remove(child: firstChild)
        }
    }
}
