#if !os(macOS)
import UIKit

/// List UI setting protocol
@MainActor
public protocol List: AnyObject, AnalyticsScreenName {
    associatedtype T: UIView
    /// usecase for list
    associatedtype Usecase

    /// need pullToRefresh or not
    var pullToRefreshable: Bool { get }
    /// hide navigation bar or not
    var hideNavigationBar: Bool { get }
    /// appear whrn data is empty
    var emptyView: UIView? { get }
    var topView: T? { get }
    var topViewHeight: CGFloat { get }
    /// child or SegmentedPageContainer or not
    var hasSegmentedPageContainer: Bool { get }
    /// screen background colot
    var backgroundColor: UIColor { get }
    /// domain usecase of list
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
#endif
