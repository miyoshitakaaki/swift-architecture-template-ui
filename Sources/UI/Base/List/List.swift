import UIKit

public protocol List: AnyObject {
    associatedtype T: UIView

    var hideNavigationBar: Bool { get }
    var emptyView: UIView { get }
    var topView: T? { get }
    var topViewHeight: CGFloat { get }
    var hasSegmentedPageContainer: Bool { get }
    var backgroundColor: UIColor { get }
}

public extension List {
    var hideNavigationBar: Bool { false }
}
