import Combine
import SkeletonView
import UIKit
import Utility

public protocol CollectionViewControllerDelegate: AnyObject {
    // TODO: should not use generic parameter
    func didItemSelected(selectedInfo: SelectedCellInfo<some CollectionList>)
    func didCellDequeued<T: UICollectionViewCell>(cell: T?, indexPath: IndexPath)
    func didSupplementaryViewDequeued(supplementaryView: UICollectionReusableView?)
    func didErrorOccured(error: AppError)
}

extension CollectionViewController: VCInjectable {
    public typealias VM = ListViewModel<
        T.Cell.ViewData,
        T.Parameter,
        T.Header.ViewData,
        T.Footer.ViewData
    >
    public typealias UI = CollectionUI<T>
}

// MARK: - stored properties

public final class CollectionViewController<
    T: CollectionList,
    C: NavigationContent
>: ViewController,
    ActivityPresentable
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public weak var delegate: CollectionViewControllerDelegate?

    private var reloadType: ReloadType?

    override public var screenNameForAnalytics: [AnalyticsScreen] {
        self.collection.screenNameForAnalytics
    }

    override public var screenEventForAnalytics: [AnalyticsEvent] {
        self.collection.screenEventForAnalytics
    }

    private let collection: T
    private let content: C
    private let needRefreshNotificationNames: [Notification.Name]

    public init(
        collection: T,
        content: C,
        needRefreshNotificationNames: [Notification.Name] = []
    ) {
        self.collection = collection
        self.content = content
        self.needRefreshNotificationNames = needRefreshNotificationNames
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = self.collection.backgroundColor

        self.view.isSkeletonable = true

        self.setupNavigationBar(content: self.content)

        self.ui.setupView(rootview: view)

        self.ui.setupBottomAnchor(
            hasTabber: self.tabBarController != nil,
            rootview: view
        )

        self.setupEvent()

        self.addObserver()

        self.viewModel.loadSubject.send((nil, false))
        self.reloadType = nil
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(
            self.collection.hideNavigationBar,
            animated: true
        )

        if self.reloadType != nil {
            self.viewModel.loadSubject.send((nil, false))
            self.reloadType = nil
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false
    }

    override public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        if self.reloadType != nil {
            self.viewModel.loadSubject.send((nil, false))
            self.reloadType = nil
        }
    }

    private func addObserver() {
        self.needRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .current
            ) { _ in
                self.reloadType = .remote
            }
        }
    }

    private func setupEvent() {
        self.ui.refreshPublisher
            .sink { [weak self] _ in
                self?.viewModel.loadSubject.send((nil, false))
            }.store(in: &self.cancellables)

        self.ui.additionalLoadingIndexPathPublisher
            .sink { [weak self] _ in
                self?.viewModel.loadSubject.send((nil, true))
            }.store(in: &self.cancellables)

        self.ui.didItemSelectedPublisher
            .sink { [weak self] selectedInfo in
                self?.delegate?.didItemSelected(selectedInfo: selectedInfo)
            }.store(in: &self.cancellables)

        self.ui.didCellDequeuePublisher
            .sink { [weak self] data in
                self?.delegate?.didCellDequeued(cell: data.0, indexPath: data.1)
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

                case let .loading(value):

                    if let items = self.collection.skeletonItems, value?.isEmpty != false {
                        self.ui.reload(items: items)
                        self.view.showAnimatedGradientSkeleton()
                    } else {
                        self.presentActivity()
                    }

                case let .failed(error):
                    self.ui.endRefresh()
                    self.dismissActivity()
                    self.delegate?.didErrorOccured(error: error)
                    self.view.hideSkeleton()

                case let .done(value):
                    self.ui.endRefresh()
                    self.dismissActivity()
                    self.ui.reload(items: value)
                    self.view.hideSkeleton()

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
