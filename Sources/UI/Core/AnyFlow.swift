import Combine
import UIKit
import Utility

open class AnyFlow<Flow: FlowBase>: UIViewController, FlowController,
    AlertPresentable where Flow.T == NavigationController
{
    public var alertMessageAlignment: NSTextAlignment?

    public var alertTintColor: UIColor?

    open var childProvider: (Flow.Child) -> UIViewController {{ _ in
        .init(nibName: nil, bundle: nil)
    }}

    public var cancellables: Set<AnyCancellable> = []

    public var delegate: FlowDelegate?

    public var navigation: Flow.T

    public let root: Flow.Child

    public required init(navigation: T, root: Child) {
        self.navigation = navigation
        self.root = root
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        self.show(self.root, root: true)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.navigation.viewControllers.isEmpty == true {
            self.show(self.root, root: true)
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        children.first?.view.frame = view.bounds
    }
}
