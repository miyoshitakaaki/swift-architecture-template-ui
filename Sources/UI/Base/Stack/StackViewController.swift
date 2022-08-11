import Combine
import UIKit

extension StackViewController: VCInjectable {
    public typealias VM = NoViewModel
    public typealias UI = StackUI<T>
}

// MARK: - stored properties

public final class StackViewController<T: Stack>: UIViewController {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    private let component: T

    private let fetch: () -> Void

    public init(component: T, fetch: @escaping () -> Void) {
        self.component = component
        self.fetch = fetch
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

        self.fetch()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}
