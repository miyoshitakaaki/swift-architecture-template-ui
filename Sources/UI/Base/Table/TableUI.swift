import Combine
import OrderedCollections
import UIKit

public final class TableUI<T: Table>: ListUI<T>, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView

    private var viewDataItems: OrderedDictionary<String, [T.Cell.ViewData]>

    let didCellDequeuedPublisher = PassthroughSubject<(T.Cell, IndexPath), Never>()
    let didItemSelectedPublisher = PassthroughSubject<IndexPath, Never>()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<IndexPath, Never>()
    let refreshPublisher = PassthroughSubject<Void, Never>()

    private let table: T

    public init(
        style: UITableView.Style = .plain,
        viewDataItems: OrderedDictionary<String, [T.Cell.ViewData]> = [:],
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
    ) -> Int { self.viewDataItems.elements[section].value.count }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.Cell.className) as? T.Cell
        else { return .init() }
        cell.viewData = self.viewDataItems.elements[indexPath.section].value[indexPath.row]
        cell.selectionStyle = .none
        self.didCellDequeuedPublisher.send((cell, indexPath))
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didItemSelectedPublisher.send(indexPath)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        self.viewDataItems.count
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
        let header = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: T.Header.className) as? T.Header

        return header
    }

    public func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        let header = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: T.Footer.className) as? T.Footer

        return header
    }

    public func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        if indexPath.row > 20, indexPath.row % 20 == 10 {
            self.additionalLoadingIndexPathPublisher.send(indexPath)
        }
    }

    private func setupEmptyView() {
        self.tableView.backgroundView = self.table.emptyView
    }

    @objc private func refresh() {
        self.refreshPublisher.send()
    }

    func endRefresh() {
        self.tableView.refreshControl?.endRefreshing()
    }
}

extension TableUI: UserInterface {
    public func setupView(rootview: UIView) {
        self.setupTableView(rootview: rootview)
        self.setupTopView(view: self.tableView)
        self.setupEmptyView()
    }

    func setupTableView(rootview: UIView) {
        rootview.addSubviews(
            self.tableView,
            constraints:
            self.tableView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.tableView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor),
            self.tableView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor)
        )

        self.tableView.backgroundColor = self.table.backgroundColor
        self.tableView.separatorStyle = .none
        self.tableView.refreshControl = UIRefreshControl()
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

    func reload(items: OrderedDictionary<String, [T.Cell.ViewData]>) {
        self.table.emptyView?.isHidden = !items.elements.isEmpty
        self.viewDataItems = items
        self.tableView.reloadData()
    }
}
