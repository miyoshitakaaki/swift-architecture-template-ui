import UIKit
import Utility

open class AnyFlow<Flow: FlowBase>: UIViewController, FlowController,
    AlertPresentable where Flow.T == NavigationController
{
    open var childProvider: (Flow.Child) -> UIViewController {{ _ in
        .init(nibName: nil, bundle: nil)
    }}

    open var asyncChildProvider: ((Child) async -> UIViewController)? { nil }

    public weak var delegate: FlowDelegate?

    public var navigation: Flow.T

    public let root: Flow.Child

    public let from: any FlowController.Type

    public let alertMessageAlignment: NSTextAlignment?

    public let alertTintColor: UIColor?

    private let isFirstFlow: Bool

    public required init(
        navigation: NavigationController,
        root: Flow.Child,
        from: any FlowController.Type,
        alertMessageAlignment: NSTextAlignment?,
        alertTintColor: UIColor?
    ) {
        self.isFirstFlow = navigation.viewControllers.isEmpty
        self.navigation = navigation
        self.root = root
        self.from = from
        self.alertMessageAlignment = alertMessageAlignment
        self.alertTintColor = alertTintColor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if self.isFirstFlow {
            self.clear()
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        if self.asyncChildProvider == nil {
            self.start()
        } else if self.navigation.viewControllers.isEmpty == false {
            self.start()
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.navigation.viewControllers.isEmpty == true {
            self.start()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        children.first?.view.frame = view.bounds
    }

    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        guard let presentationController = self.presentationController else {
            return
        }
        presentationController.delegate?.presentationControllerDidDismiss?(presentationController)
    }

    open func start() {
        self.show(self.root, root: true)
    }
}
