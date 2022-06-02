import UIKit

public final class TableEmptyHeader: UITableViewHeaderFooterView, TableViewHeader {
    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .red
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(title: String) {}
}
