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
>: ViewController, ActivityPresentable, DiffableCollectionUIDelegate {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    private var reloadType: ReloadType?

    override public var screenNameForAnalytics: [AnalyticsScreen] { self._screenNameForAnalytics }

    override public var screenEventForAnalytics: [AnalyticsEvent] { self._screenEventForAnalytics }

    private let content: C
    private let _screenEventForAnalytics: [AnalyticsEvent]
    private let _screenNameForAnalytics: [AnalyticsScreen]
    private let needRefreshNotificationNames: [Notification.Name]
    private let needSectionRefreshNotificationNames: [(
        name: Notification.Name,
        sectionIndexes: [Int]
    )]

    public init(
        initialReloadType: ReloadType = .remote,
        content: C,
        screenNameForAnalytics: [AnalyticsScreen] = [],
        screenEventForAnalytics: [AnalyticsEvent] = [],
        needRefreshNotificationNames: [Notification.Name] = [],
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

        self.addObserver()

        self.reload()
        self.reloadType = nil
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.reloadType != nil {
            self.reload()
            self.reloadType = nil
        }
    }

    override public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        if self.reloadType != nil {
            self.reload()
            self.reloadType = nil
        }
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
        self.needRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .current
            ) { _ in
                self.reloadType = .remote
            }
        }

        self.needSectionRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName.name,
                object: nil,
                queue: .current
            ) { _ in
                self.reloadType = .remoteOnlySection(sections: notificationName.sectionIndexes)
            }
        }
    }

    private func reload() {
        guard let reloadType = self.reloadType else { return }

        switch reloadType {
        case .local:
            self.ui.reload(fetchRemote: false) { result in
                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.ui.reloadSection(section: section, fetchRemote: false)
                    }

                case .failure:
                    break
                }
            }
        case let .remoteOnlySection(indexes):
            self.ui.reload(fetchRemote: false) { result in
                switch result {
                case let .success(sections):
                    sections.enumerated().forEach { [weak self] index, section in
                        if indexes.contains(index) {
                            self?.ui.reloadSection(section: section, fetchRemote: true)
                        } else {
                            self?.ui.reloadSection(section: section, fetchRemote: false)
                        }
                    }

                case .failure:
                    break
                }
            }
        case .remote:
            self.ui.reload(fetchRemote: true) { result in
                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.ui.reloadSection(section: section, fetchRemote: true)
                    }

                case .failure:
                    break
                }
            }
        }
    }
}
