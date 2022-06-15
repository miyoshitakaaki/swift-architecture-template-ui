import Combine
import OrderedCollections
import UI
import UIKit
import Utility

public class MessageListTableViewCell: UITableViewCell, TableViewCell {
    public typealias ViewData = String

    private let label = UILabel(style: .darkGlay97MediumSize, title: "item")

    public var viewData: ViewData? {
        didSet {
            self.label.text = viewData
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.label.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.contentView.edgeToSelf(self.label)
        self.backgroundColor = .lightGray
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class SampleTable: Table {
    public typealias Cell = MessageListTableViewCell
    public typealias Header = TableEmptyHeader

    public var emptyView: UIView = UILabel(style: .darkGlay97MediumSize, title: "結果がありません")

    public var topView: UIView? { nil }

    public var topViewHeight: CGFloat { 0 }

    public var showSearchBar: Bool { false }

    public var hasSegmentedPageContainer: Bool { true }

    public var reloadable: Bool { true }

    public var viewDidLoadFetch: Bool { true }

    public var backgroundColor: UIColor { .yellow }

    public var fetchPublisher: ((parameter: String?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> {{ _ in
        Just([
            "section1": [
                "table1",
                "table2",
                "table3",
                "table4",
                "table5",
                "table6",
                "table7",
                "table8",
                "table9",
                "table10",
                "table11",
                "table12",
            ],
        ])
        .setFailureType(to: AppError.self)
        .eraseToAnyPublisher()
    }}

    public func mapper(entities: [[String]]) -> OrderedDictionary<String, [Cell.ViewData]> {
        [:]
    }

    public init() {}
}
