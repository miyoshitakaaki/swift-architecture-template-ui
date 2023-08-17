#if !os(macOS)
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
>: ViewController, ActivityPresentable, DiffableCollectionUIDelegate {
    public var viewModel: VM!
    public var ui: UI!

    private var reloadType: ReloadType?
    private var lastFetchAllDate: Date?

    override public var screenNameForAnalytics: [AnalyticsScreen] { self._screenNameForAnalytics }

    override public var screenEventForAnalytics: [AnalyticsEvent] { self._screenEventForAnalytics }

    private let content: C
    private let _screenEventForAnalytics: [AnalyticsEvent]
    private let _screenNameForAnalytics: [AnalyticsScreen]
    private let needRefreshNotificationNames: [Notification.Name]
    private let needForceRefreshNotificationNames: [Notification.Name]
    private let needSectionRefreshNotificationNames: [(
        name: Notification.Name,
        sectionIndexes: [Int]
    )]

    public init(
        initialReloadType: ReloadType = .remote(),
        content: C,
        screenNameForAnalytics: [AnalyticsScreen] = [],
        screenEventForAnalytics: [AnalyticsEvent] = [],
        needRefreshNotificationNames: [Notification.Name] = [],
        needForceRefreshNotificationNames: [Notification.Name] = [],
        needSectionRefreshNotificationNames: [(
            name: Notification.Name,
            sectionIndexes: [Int]
        )] = []
    ) {
        self.reloadType = initialReloadType
        self.content = content
        self._screenNameForAnalytics = screenNameForAnalytics
        self._screenEventForAnalytics = screenEventForAnalytics
        self.needRefreshNotificationNames = needRefreshNotificationNames
        self.needForceRefreshNotificationNames = needForceRefreshNotificationNames
        self.needSectionRefreshNotificationNames = needSectionRefreshNotificationNames
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

        self.ui.bind()

        self.ui.setupBottomAnchor(
            hasTabber: self.tabBarController != nil,
            rootview: view
        )

        self.addObserver()

        self.reload()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.reload()
    }

    override public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        self.reload()
    }

    public func willfetchAll(pullToRefresh: Bool) {
        if pullToRefresh == false {
            self.presentActivity()
        }
    }

    public func didfetchAll() {
        self.dismissActivity()
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .current
        ) { [weak self] _ in

            guard let self else { return }

            let isVisible = self.isViewLoaded && self.view.window != nil

            guard isVisible else { return }

            self.reload()
        }

        self.needRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .current
            ) { [weak self] _ in
                self?.reloadType = .remote()
            }
        }

        self.needForceRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .current
            ) { [weak self] _ in
                self?.reloadType = .remote(force: true)
            }
        }

        self.needSectionRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName.name,
                object: nil,
                queue: .current
            ) { [weak self] _ in
                self?.reloadType = .remoteOnlySection(sections: notificationName.sectionIndexes)
            }
        }
    }

    private func reload() {
        defer {
            self.reloadType = nil
        }

        guard let reloadType = self.reloadType else { return }

        switch reloadType {
        case .local:
            self.ui.setSections(fetchRemote: false) { result in
                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.ui.setItems(section: section, fetchRemote: false)
                    }

                case .failure:
                    break
                }
            }
        case let .remoteOnlySection(indexes):
            self.ui.setSections(fetchRemote: false) { result in
                switch result {
                case let .success(sections):
                    sections.enumerated().forEach { [weak self] index, section in
                        if indexes.contains(index) {
                            self?.ui.setItems(section: section, fetchRemote: true)
                        } else {
                            self?.ui.setItems(section: section, fetchRemote: false)
                        }
                    }

                case .failure:
                    break
                }
            }
        case let .remote(force):

            let needFetchAll: Bool = {
                if force { return true }

                if
                    let fetchAllMinuteInterval = S.fetchAllMinuteInterval,
                    let lastFetchAllDate = self.lastFetchAllDate
                {
                    let ago = Date().addingTimeInterval(.init(fetchAllMinuteInterval * 60 * -1))
                    return ago.compare(lastFetchAllDate) == .orderedDescending
                } else {
                    return true
                }
            }()

            guard needFetchAll else { return }

            self.lastFetchAllDate = .init()

            self.ui.setSections(fetchRemote: true) { result in
                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.ui.setItems(section: section, fetchRemote: true)
                    }

                case .failure:
                    break
                }
            }
        }
    }
}
#endif
