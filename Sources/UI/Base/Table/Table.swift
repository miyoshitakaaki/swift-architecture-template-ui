import Combine
import UIKit
import Utility

public protocol Table: List {
    associatedtype Cell: TableViewCell
    associatedtype EmptyCell: UITableViewCell
    associatedtype Header: TableViewHeaderFooter
    associatedtype Footer: TableViewHeaderFooter
    associatedtype Entity
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData>]

    var showSearchBar: Bool { get }
    var fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> { get }
    func mapper(entities: [[Entity]]) -> Items
}

public extension Table {
    var showSearchBar: Bool { false }
}

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

public protocol TableViewHeaderFooter: UITableViewHeaderFooterView {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}
