import Combine
import OrderedCollections
import UIKit

public final class TableUI<T: Table>: ListUI<T>, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView

    private var viewDataItems: OrderedDictionary<String, [T.Cell.ViewData]>

    let didItemSelectedPublisher = PassthroughSubject<IndexPath, Never>()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<IndexPath, Never>()

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
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let header = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: T.Header.className) as? T.Header
        header?.configure(
            title: self.viewDataItems.keys.isEmpty
                ? ""
                : self.viewDataItems.keys[section]
        )
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
}

extension TableUI: UserInterface {
    public func setupView(rootview: UIView) {
        self.setupEmptyView(rootview: rootview)
        self.setupTableView(rootview: rootview)
        self.setupTopView(view: self.tableView)
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
        self.tableView.register(T.Cell.self, forCellReuseIdentifier: T.Cell.className)
        self.tableView.register(
            T.Header.self,
            forHeaderFooterViewReuseIdentifier: T.Header.className
        )
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.isHidden = self.viewDataItems.elements.isEmpty
    }

    func reload(items: OrderedDictionary<String, [T.Cell.ViewData]>) {
        self.tableView.isHidden = items.elements.isEmpty
        self.viewDataItems = items
        self.tableView.reloadData()
    }
}
