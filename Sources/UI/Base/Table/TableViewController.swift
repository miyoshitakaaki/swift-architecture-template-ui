import Combine
import UIKit
import Utility

public struct SelectedTableCellInfo<T: Table> {
    public let indexPath: IndexPath
    public let viewData: T.Cell.ViewData?
}

public struct SelectedTableCell<T: Table> {
    public let indexPath: IndexPath
    public let cell: T.Cell?
}

public protocol TableViewControllerDelegate: AnyObject {
    func didItemSelected(cellData: SelectedTableCellInfo<some Table>)
    func didCellDequeued(cell: SelectedTableCell<some Table>)
    func didHeaderFooterDequeued(
        tableViewHeaderFooterView: UITableViewHeaderFooterView?,
        section: Int
    )
    func didSearchCancelButtonTapped()
    func didSearchTextUpdated(text: String?)
    func didErrorOccured(error: AppError)
}

extension TableViewController: VCInjectable {
    public typealias VM = ListViewModel<
        T.Cell.ViewData,
        T.Parameter,
        T.Header.ViewData,
        T.Footer.ViewData
    >
    public typealias UI = TableUI<T>
}

// MARK: - stored properties

public final class TableViewController<T: Table>: ViewController,
    ActivityPresentable,
    UISearchBarDelegate,
    Refreshable
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public weak var delegate: TableViewControllerDelegate?

    // TODO: move to TableUI
    private var searchBar: UISearchBar!

    private let table: T

    private var needReflesh = false

    override public var screenNameForAnalytics: String {
        self.table.screenNameForAnalytics
    }

    override public var screenEventForAnalytics: [AnalyticsEvent] {
        self.table.screenEventForAnalytics
    }

    public init(table: T) {
        self.table = table
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = self.table.backgroundColor

        self.ui.setupView(rootview: view)

        if self.table.showSearchBar {
            let searchBar = UISearchBar(frame: navigationController?.navigationBar.bounds ?? .zero)
            searchBar.delegate = self
            searchBar.placeholder = "メッセージを検索"
            searchBar.tintColor = .gray
            searchBar.keyboardType = .default
            searchBar.showsCancelButton = true
            self.searchBar = searchBar
        }

        self.bind()

        self.viewModel.loadSubject.send((nil, false))
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.setupNavigationItemIfNeeded()

        if self.needReflesh {
            self.viewModel.loadSubject.send((nil, false))
            self.needReflesh = false
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.view.endEditing(true)
    }

    override public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        if self.needReflesh {
            self.viewModel.loadSubject.send((nil, false))
            self.needReflesh = false
        }
    }

    public func setNeedRefresh() {
        self.needReflesh = true
    }

    private func setupNavigationItemIfNeeded() {
        guard self.table.showSearchBar else { return }

        let navigationItem =
            ((self.parent as? SegmentedPageContainer<BadgeSegmentedControl>) ?? self).navigationItem
        navigationItem.setRightBarButtonItems(nil, animated: true)
        navigationItem.titleView = self.searchBar
        navigationItem.titleView?.frame = self.searchBar.frame
        self.searchBar.becomeFirstResponder()
    }

    private func bind() {
        self.ui.refreshPublisher
            .sink { [weak self] _ in
                self?.viewModel.loadSubject.send((nil, false))
            }.store(in: &self.cancellables)

        self.ui.didItemSelectedPublisher
            .sink { [weak self] indexPath in
                guard let self = self else { return }
                let viewData = self.viewModel.loadingState.value.value?[indexPath.section]
                    .items[indexPath.row]
                self.delegate?
                    .didItemSelected(cellData: SelectedTableCellInfo<T>(
                        indexPath: indexPath,
                        viewData: viewData
                    ))
            }
            .store(in: &self.cancellables)

        self.ui.didCellDequeuedPublisher
            .sink { [weak self] cell, indexPath in
                guard let self = self else { return }
                self.delegate?
                    .didCellDequeued(
                        cell: SelectedTableCell<T>
                            .init(indexPath: indexPath, cell: cell)
                    )
            }
            .store(in: &self.cancellables)

        self.ui.didHeaderDequeuedPublisher
            .sink { [weak self] header, section in
                guard let self = self else { return }
                self.delegate?.didHeaderFooterDequeued(
                    tableViewHeaderFooterView: header,
                    section: section
                )
            }
            .store(in: &self.cancellables)

        self.ui.didFooterDequeuedPublisher
            .sink { [weak self] footer, section in
                guard let self = self else { return }
                self.delegate?.didHeaderFooterDequeued(
                    tableViewHeaderFooterView: footer,
                    section: section
                )
            }
            .store(in: &self.cancellables)

        self.viewModel.bind().store(in: &self.cancellables)

        self.viewModel.loadingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .standby:
                    self.ui.endRefresh()
                    self.dismissActivity()

                case .loading:
                    self.presentActivity()

                case let .failed(error):
                    self.ui.endRefresh()
                    self.dismissActivity()
                    self.delegate?.didErrorOccured(error: error)

                case let .done(value):
                    self.ui.endRefresh()
                    self.dismissActivity()
                    self.ui.reload(items: value)

                case .addtionalDone:
                    break
                }
            }.store(in: &self.cancellables)

        self.ui.additionalLoadingIndexPathPublisher
            .sink {
                self.viewModel.loadSubject.send((nil, true))
            }.store(in: &self.cancellables)
    }

    public func fetch(query: T.Parameter?) {
        self.viewModel.loadSubject.send((query, false))
        self.searchBar.text = query as? String
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        self.delegate?.didSearchTextUpdated(text: searchBar.text)
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.delegate?.didSearchCancelButtonTapped()
    }
}
