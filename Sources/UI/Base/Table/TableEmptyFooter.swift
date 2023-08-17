#if !os(macOS)
import UIKit

public final class TableEmptyFooter: UITableViewHeaderFooterView, TableViewHeaderFooter {
    public var viewData: String? {
        didSet {}
    }

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .red
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
