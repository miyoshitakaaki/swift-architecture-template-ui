import Combine
import OrderedCollections
import UIKit
import Utility

public protocol Table: List {
    associatedtype Cell: TableViewCell
    associatedtype Header: TableViewHeader
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
    var backgroundColor: UIColor { UIColor.rgba(244, 244, 244, 1) }
}

public protocol TableViewCell: UITableViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}

public protocol TableViewHeader: UITableViewHeaderFooterView {
    func configure(title: String)
}
