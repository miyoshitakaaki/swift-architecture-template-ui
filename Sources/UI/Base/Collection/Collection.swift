#if !os(macOS)
import Combine
import UIKit
import Utility

/// Collection UI setting protocol
@MainActor
public protocol CollectionList: List, AnalyticsScreenName {
    /// navigation content type
    associatedtype NavContent: NavigationContent
    /// cell type constraint to CollectionLayout
    associatedtype Cell: CollectionLayout
    /// header type constraint to CollectionHeaderLayout
    associatedtype Header: CollectionHeaderLayout
    /// Footer type constraint to CollectionFooterLayout
    associatedtype Footer: CollectionFooterLayout
    /// paramter for fetch request type
    associatedtype Parameter

    /// view model for colletion ui
    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    /// layout setting
    var sectionLayout: (CGFloat) -> NSCollectionLayoutSection { get }
    /// data fetch
    var fetch: ((parameter: Parameter?, isAdditional: Bool)) async
        -> Result<Items, AppError> { get }
    /// delete item of list
    var delete: (Cell.ViewData) async -> Result<Void, AppError> { get }
    /// floating button ui
    var floatingButton: UIButton? { get }
    /// titlel setting using item count
    var titleForItemCount: ((Int) -> String)? { get }
}

public extension CollectionList {
    var floatingButton: UIButton? { nil }
    var titleForItemCount: ((Int) -> String)? { nil }

    var delete: (Cell.ViewData) async -> Result<Void, AppError> {{ _ in
        Result.success(())
    }}
}

@MainActor
public protocol CollectionLayout: UICollectionViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
    var delete: ((IndexPath) -> Void)? { get set }
    var indexPath: IndexPath? { get set }
}

public extension CollectionLayout {
    var delete: ((IndexPath) -> Void)? {
        get { nil }
        set {}
    }

    var indexPath: IndexPath? {
        get { nil }
        set {}
    }
}

@MainActor
public protocol CollectionHeaderLayout: UICollectionReusableView {
    associatedtype ViewData: Equatable & Hashable
    func updateHeader(data: ViewData)
}

@MainActor
public protocol CollectionFooterLayout: UICollectionReusableView {
    associatedtype ViewData: Equatable & Hashable
    func updateFooter(data: ViewData)
}
#endif
