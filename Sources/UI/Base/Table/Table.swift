import Combine
import OrderedCollections
import UIKit
import Utility

public protocol Table: List {
    associatedtype Cell: TableViewCell
    associatedtype EmptyCell: UITableViewCell
    associatedtype Header: TableViewHeaderFooter
    associatedtype Footer: TableViewHeaderFooter
    associatedtype Entity
    associatedtype Parameter

    typealias Items = OrderedDictionary<String, [Cell.ViewData]>

    var viewDidLoadFetch: Bool { get }
    var showSearchBar: Bool { get }
    var reloadable: Bool { get }
    var fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> { get }
    func mapper(entities: [[Entity]]) -> OrderedDictionary<String, [Cell.ViewData]>
}

public extension Table {
    var showSearchBar: Bool { false }
}

public protocol TableViewCell: UITableViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}

public protocol TableViewHeaderFooter: UITableViewHeaderFooterView {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}
