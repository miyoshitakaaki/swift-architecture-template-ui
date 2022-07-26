import Combine
import UIKit

public protocol CollectionViewControllerDelegate: AnyObject {
    // TODO: should not use generic parameter
    func didItemSelected<T: CollectionList>(selectedInfo: SelectedCellInfo<T>)
    func didCellDequeued<T: UICollectionViewCell>(cell: T?)
    func didSupplementaryViewDequeued(supplementaryView: UICollectionReusableView?)
}

extension CollectionViewController: VCInjectable {
    public typealias VM = ListViewModel<T.Cell.ViewData, T.Parameter>
    public typealias UI = CollectionUI<T>
}

// MARK: - stored properties

public final class CollectionViewController<T: CollectionList>: UIViewController,
    ActivityPresentable,
    AlertPresentable
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public weak var delegate: CollectionViewControllerDelegate?

    /// 画面を閉じる時に呼ばれる
    /// 戻るボタンのイベントとして扱う 閉じるボタンは拾えない
    public let willDismissFromParent: PassthroughSubject<Void, Never> = .init()

    private let collection: T

    public init(collection: T) {
        self.collection = collection
        super.init(nibName: nil, bundle: nil)
        title = collection.screenTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = self.collection.backgroundColor

        self.ui.setupView(rootview: view)

        self.setupEvent()

        self.viewModel.loadSubject.send((nil, false))
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tabBarController?.tabBar.isHidden = self.collection.hideTabbar

        navigationController?.setNavigationBarHidden(
            self.collection.hideNavigationBar,
            animated: true
        )
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false

        if self.isMovingFromParent {
            self.willDismissFromParent.send(())
        }
    }

    private func setupEvent() {
        self.ui.refreshPublisher
            .sink { [weak self] _ in
                self?.viewModel.loadSubject.send((nil, false))
            }.store(in: &self.cancellables)

        self.ui.additionalLoadingIndexPathPublisher
            .sink { [weak self] indexPath in
                
                guard let self = self else { return }

                let current = self.viewModel.loadingState.value.value?.flatMap { $0 }.count ?? 0

                // TODO: condider section
                if current >= 20, indexPath.row == (current - 10) {
                    self.viewModel.loadSubject.send((nil, true))
                }
            }.store(in: &self.cancellables)

        self.ui.didItemSelectedPublisher
            .sink { [weak self] selectedInfo in
                self?.delegate?.didItemSelected(selectedInfo: selectedInfo)
            }.store(in: &self.cancellables)

        self.ui.didCellDequeuePublisher
            .sink { [weak self] cell in
                self?.delegate?.didCellDequeued(cell: cell)
            }.store(in: &self.cancellables)

        self.ui.didSupplementaryViewDequeuePublisher
            .sink { [weak self] supplementaryView in
                self?.delegate?.didSupplementaryViewDequeued(supplementaryView: supplementaryView)
            }.store(in: &self.cancellables)

        self.viewModel.loadingState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in

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
                    self.present(error)

                case let .done(value):
                    self.ui.endRefresh()
                    self.dismissActivity()
                    self.ui.reload(items: value)

                case .addtionalDone:
                    break
                }
            }).store(in: &self.cancellables)

        self.viewModel.bind().store(in: &self.cancellables)

        self.collection.topViewSubject
            .sink(receiveCompletion: { _ in }) { [weak self] parameter in
                guard let self = self else { return }
                self.viewModel.loadSubject.send((parameter, false))
            }
            .store(in: &self.cancellables)
    }
}
