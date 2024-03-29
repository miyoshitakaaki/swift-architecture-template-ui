#if !os(macOS)
import UIKit
import Utility

extension StackViewController: VCInjectable {
    public typealias VM = NoViewModel
    public typealias UI = StackUI<T>
}

// MARK: - stored properties

public final class StackViewController<T: Stack>: ViewController {
    public var viewModel: VM!
    public var ui: UI!

    override public var screenNameForAnalytics: [AnalyticsScreen] {
        self.component.screenNameForAnalytics
    }

    override public var screenEventForAnalytics: [AnalyticsEvent] {
        self.component.screenEventForAnalytics
    }

    private let component: T

    private let content: NavigationContent

    private let fetch: () async -> Void

    public init(
        component: T,
        content: NavigationContent,
        fetch: @escaping () async -> Void
    ) {
        self.component = component
        self.fetch = fetch
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        self.ui.setupView(rootview: view)

        self.ui.setupBottomAnchor(
            hasTabber: self.tabBarController != nil,
            rootview: view
        )

        self.setupNavigationBar(content: self.content)

        Task {
            await self.fetch()
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}
#endif
