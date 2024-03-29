#if !os(macOS)
import Combine
import UIKit

public final class TableUI<T: Table>: ListUI<T>, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView

    private var viewDataItems: T.Items

    let didCellDequeuedPublisher = PassthroughSubject<(T.Cell, IndexPath), Never>()
    let didHeaderDequeuedPublisher = PassthroughSubject<(T.Header, Int), Never>()
    let didFooterDequeuedPublisher = PassthroughSubject<(T.Footer, Int), Never>()
    let didItemSelectedPublisher = PassthroughSubject<IndexPath, Never>()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<Void, Never>()
    let refreshPublisher = PassthroughSubject<Void, Never>()

    private let table: T

    public init(
        style: UITableView.Style = .plain,
        viewDataItems: T.Items = [],
        table: T
    ) {
        self.tableView = UITableView(frame: .zero, style: style)
        self.tableView.sectionHeaderHeight = 0
        self.tableView.keyboardDismissMode = .interactive
        self.viewDataItems = viewDataItems
        self.table = table
        super.init(list: table)
    }

    public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if self.viewDataItems.isEmpty {
            return 1
        } else {
            return self.viewDataItems[section].items.count
        }
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.Cell.className) as? T.Cell
        else { return .init() }
        cell.viewData = self.viewDataItems[indexPath.section].items[indexPath.row]
        cell.deleteItem = self.deleteItem
        cell.selectionStyle = .none
        self.didCellDequeuedPublisher.send((cell, indexPath))
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didItemSelectedPublisher.send(indexPath)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.viewDataItems.isEmpty {
            return 1
        } else {
            return self.viewDataItems.count
        }
    }

    public func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        if T.Header.self == TableEmptyHeader.self {
            return 0
        } else {
            return 30
        }
    }

    public func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        if T.Footer.self == TableEmptyFooter.self {
            return 0
        } else {
            return 142
        }
    }

    public func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard
            let header = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: T.Header.className) as? T.Header
        else { return nil }

        self.didHeaderDequeuedPublisher.send((header, section))
        return header
    }

    public func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        guard
            let footer = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: T.Footer.className) as? T.Footer
        else { return nil }

        self.didFooterDequeuedPublisher.send((footer, section))

        return footer
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.tableView else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.frame.height
        let contentInset = scrollView.contentInset
        let viewedHeight = offsetY + viewHeight - contentInset.bottom
        if viewedHeight > contentHeight {
            self.additionalLoadingIndexPathPublisher.send(())
        }
    }

    private func setupEmptyView() {
        self.tableView.backgroundView = self.table.emptyView
        self.table.emptyView?.isHidden = true
    }

    @objc private func refresh() {
        self.refreshPublisher.send()
    }

    func endRefresh() {
        self.tableView.refreshControl?.endRefreshing()
    }

    var deleteItem: (IndexPath) -> Void { { [weak self] indexPath in
        guard let self else { return }
        var values = self.viewDataItems[indexPath.section].items
        values.remove(at: indexPath.row)
        if values.isEmpty {
            self.viewDataItems = []
        } else {
            self.viewDataItems[indexPath.section].items = values
        }
        self.tableView.reloadData()
    }}
}

extension TableUI: UserInterface {
    public func setupView(rootview: UIView) {
        self.setupTableView(rootview: rootview)
        self.setupTopView(view: self.tableView)
        self.setupEmptyView()
    }

    func setupBottomAnchor(hasTabber: Bool, rootview: UIView) {
        if hasTabber {
            self.tableView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.tableView.bottomAnchor.constraint(equalTo: rootview.bottomAnchor).isActive = true
        }
    }

    func setupTableView(rootview: UIView) {
        rootview.addSubviews(
            self.tableView,
            constraints:
            self.tableView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.tableView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor)
        )

        self.tableView.backgroundColor = self.table.backgroundColor
        self.tableView.separatorStyle = .none

        if self.table.pullToRefreshable {
            self.tableView.refreshControl = UIRefreshControl()
        }

        self.tableView.refreshControl?.addTarget(
            self,
            action: #selector(self.refresh),
            for: .valueChanged
        )
        self.tableView.register(T.Cell.self, forCellReuseIdentifier: T.Cell.className)
        self.tableView.register(
            T.Header.self,
            forHeaderFooterViewReuseIdentifier: T.Header.className
        )
        self.tableView.register(
            T.Footer.self,
            forHeaderFooterViewReuseIdentifier: T.Footer.className
        )
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    func reload(items: T.Items) {
        self.table.emptyView?.isHidden = !items.isEmpty
        self.viewDataItems = items
        self.tableView.reloadData()
    }
}
#endif
