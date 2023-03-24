import UIKit
import Utility

public protocol Table: List, AnalyticsScreenName {
    associatedtype NavContent: NavigationContent
    associatedtype Cell: TableViewCell
    associatedtype EmptyCell: UITableViewCell
    associatedtype Header: TableViewHeaderFooter
    associatedtype Footer: TableViewHeaderFooter
    associatedtype Entity
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    var showSearchBar: Bool { get }
    var fetch: ((parameter: Parameter?, isAdditional: Bool)) async
        -> Result<Items, AppError> { get }
    func mapper(entities: [[Entity]]) -> Items
    var skeletonItems: Items? { get }
}

public extension Table {
    var showSearchBar: Bool { false }
    var skeletonItems: Items? { nil }
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
