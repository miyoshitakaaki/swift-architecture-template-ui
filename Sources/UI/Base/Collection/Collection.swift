#if !os(macOS)
import Combine
import UIKit
import Utility

@MainActor
public protocol CollectionList: List, AnalyticsScreenName {
    associatedtype NavContent: NavigationContent
    associatedtype Cell: CollectionLayout
    associatedtype Header: CollectionHeaderLayout
    associatedtype Footer: CollectionFooterLayout
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    var sectionLayout: (CGFloat) -> NSCollectionLayoutSection { get }
    var topViewSubject: PassthroughSubject<Parameter, Never> { get }
    var fetch: ((parameter: Parameter?, isAdditional: Bool)) async
        -> Result<Items, AppError> { get }
    var delete: (Cell.ViewData) async -> Result<Void, AppError> { get }
    var floatingButton: UIButton? { get }
    var titleForItemCount: ((Int) -> String)? { get }
}

public extension CollectionList {
    var floatingButton: UIButton? { nil }
    var topViewSubject: PassthroughSubject<String, Never> { .init() }
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
