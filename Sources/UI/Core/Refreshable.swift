import UIKit

public protocol Refreshable: UIViewController {
    func setNeedRefresh()
    func setNeedfetchRemote()
}

public extension Refreshable {
    func setNeedfetchRemote() {}
}
