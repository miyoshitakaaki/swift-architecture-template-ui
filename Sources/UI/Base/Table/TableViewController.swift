import Combine
import UIKit

public protocol TableViewControllerDelegate: AnyObject {
    func didItemSelected<T: Table>(indexPath: IndexPath, table: T, cellData: T.Cell.ViewData?)
    func didSearchCancelButtonTapped()
    func didSearchTextUpdated(text: String?)
}

extension TableViewController: VCInjectable {
    public typealias VM = ListViewModel<T.Cell.ViewData, T.Parameter>
    public typealias UI = TableUI<T>
}

// MARK: - stored properties

public final class TableViewController<T: Table>: UIViewController, ActivityPresentable,
    AlertPresentable,
    UISearchBarDelegate
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public weak var delegate: TableViewControllerDelegate?

    // TODO: move to TableUI
    private var searchBar: UISearchBar!

    private let table: T

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

        if self.table.viewDidLoadFetch {
            self.viewModel.loadSubject.send((nil, false))
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.setupNavigationItemIfNeeded()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.view.endEditing(true)
    }

    private func setupNavigationItemIfNeeded() {
        guard self.table.showSearchBar else { return }

        let navigationItem = ((self.parent as? SegmentedPageContainer) ?? self).navigationItem
        navigationItem.setRightBarButtonItems(nil, animated: true)
        navigationItem.titleView = self.searchBar
        navigationItem.titleView?.frame = self.searchBar.frame
        self.searchBar.becomeFirstResponder()
    }

    private func bind() {
        self.ui.didItemSelectedPublisher
            .sink { [weak self] indexPath in
                guard let self = self else { return }
                self.delegate?.didItemSelected(
                    indexPath: indexPath,
                    table: self.table,
                    cellData: self.viewModel.loadingState.value.value?
                        .elements[indexPath.section].value[indexPath.row]
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
                    self.dismissActivity()

                case .loading:
                    self.presentActivity()

                case let .failed(error):
                    self.dismissActivity()
                    self.present(error)

                case let .done(value):
                    self.dismissActivity()
                    if self.table.reloadable {
                        self.ui.reload(items: value)
                    }

                case .addtionalDone:
                    break
                }
            }.store(in: &self.cancellables)

        self.ui.additionalLoadingIndexPathPublisher
            .sink { indexPath in
                print(indexPath)
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
