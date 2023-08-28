#if !os(macOS)
import UIKit
import Utility

/// Table UI setting protocol
public protocol Table: List, AnalyticsScreenName {
    /// navigation content type
    associatedtype NavContent: NavigationContent
    /// cell type constraint to CollectionLayout
    associatedtype Cell: TableViewCell
    /// header type constraint to CollectionHeaderLayout
    associatedtype Header: TableViewHeaderFooter
    /// Footer type constraint to CollectionFooterLayout
    associatedtype Footer: TableViewHeaderFooter
    /// domain model
    associatedtype Entity
    /// paramter for fetch request type
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    /// show search bar or not
    var showSearchBar: Bool { get }
    /// fetch data
    var fetch: ((parameter: Parameter?, isAdditional: Bool)) async
        -> Result<Items, AppError> { get }
    /// mapper from domain model to view model
    func mapper(entities: [[Entity]]) -> Items
}

public extension Table {
    var showSearchBar: Bool { false }
}

@MainActor
public protocol TableViewCell: UITableViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
    var deleteItem: (IndexPath) -> Void { get set }
}

public extension TableViewCell {
    var deleteItem: (IndexPath) -> Void {
        get { { _ in } }
        set {}
    }
}

@MainActor
public protocol TableViewHeaderFooter: UITableViewHeaderFooterView {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}
#endif
