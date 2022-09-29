import UIKit

public protocol List: AnyObject, AnalyticsScreenName {
    associatedtype T: UIView
    associatedtype Usecase

    var pullToRefreshable: Bool { get }
    var hideNavigationBar: Bool { get }
    var emptyView: UIView? { get }
    var topView: T? { get }
    var topViewHeight: CGFloat { get }
    var hasSegmentedPageContainer: Bool { get }
    var backgroundColor: UIColor { get }
    var listUsecase: Usecase { get }
}

public extension List {
    var pullToRefreshable: Bool { false }
    var hideNavigationBar: Bool { false }
    var emptyView: UIView? { nil }
    var topView: UIView? { nil }
    var topViewHeight: CGFloat { 0 }
    var hasSegmentedPageContainer: Bool { false }
    var listUsecase: EmptyUsecase { .init() }
}
