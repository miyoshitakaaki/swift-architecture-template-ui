import UIKit

public protocol Refreshable: UIViewController {
    // TODO: rename to setNeedReload
    func setNeedRefresh()
    func setNeedfetchRemote()
}

public extension Refreshable {
    func setNeedfetchRemote() {}
}
