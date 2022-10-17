import Combine
import UIKit
import Utility

extension DiffableCollectionViewController: VCInjectable {
    public typealias VM = NoViewModel
    public typealias UI = DiffableCollectionUI<S>
}

// MARK: - stored properties

public final class DiffableCollectionViewController<
    S: DiffableCollectionSection,
    C: NavigationContent
>: ViewController, Refreshable, ActivityPresentable, DiffableCollectionUIDelegate {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    private let _screenEventForAnalytics: [AnalyticsEvent]
    private let _screenNameForAnalytics: [AnalyticsScreen]
    private let content: C

    private var needReflesh = false

    override public var screenNameForAnalytics: [AnalyticsScreen] { self._screenNameForAnalytics }

    override public var screenEventForAnalytics: [AnalyticsEvent] { self._screenEventForAnalytics }

    public init(
        content: C,
        screenNameForAnalytics: [AnalyticsScreen] = [],
        screenEventForAnalytics: [AnalyticsEvent] = []
    ) {
        self.content = content
        self._screenNameForAnalytics = screenNameForAnalytics
        self._screenEventForAnalytics = screenEventForAnalytics
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        self.ui.uiDelegate = self

        self.setupNavigationBar(content: self.content)

        self.ui.setupView(rootview: view)

        self.ui.reload()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.needReflesh {
            self.ui.reload()
            self.needReflesh = false
        }
    }

    public func setNeedRefresh() {
        self.needReflesh = true
    }

    override public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        if self.needReflesh {
            self.ui.reload()
            self.needReflesh = false
        }
    }

    public func willfetchAll() {
        self.presentActivity()
    }

    public func didfetchAll() {
        self.dismissActivity()
    }
}
