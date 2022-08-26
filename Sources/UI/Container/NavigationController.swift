import UIKit

public protocol NavigationControllerDelegate: AnyObject {
    func didPopViewController(viewController: UIViewController?)
}

open class NavigationController: UINavigationController {
    private let closeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.setTitle("✗", for: .normal)
        return button
    }()

    private let hideBackButtonText: Bool

    private let showCloseButton: Bool

    private let navigationTintColor: UIColor

    public weak var navigationControllerDelegate: NavigationControllerDelegate?

    public init(
        hideBackButtonText: Bool = false,
        showCloseButton: Bool = false,
        closeButtonColor: UIColor? = nil,
        navigationTintColor: UIColor = UIColor.rgba(17, 76, 190, 1)
    ) {
        self.hideBackButtonText = hideBackButtonText
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        self.navigationTintColor = navigationTintColor
        super.init(nibName: nil, bundle: nil)
    }

    public init(
        rootViewController: UIViewController,
        hideBackButtonText: Bool = false,
        showCloseButton: Bool = false,
        closeButtonColor: UIColor = .black,
        navigationTintColor: UIColor = UIColor.rgba(17, 76, 190, 1)
    ) {
        self.hideBackButtonText = hideBackButtonText
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        self.navigationTintColor = navigationTintColor
        super.init(rootViewController: rootViewController)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        self.navigationBar.tintColor = self.navigationTintColor
        self.closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.showCloseButton {
            let closeButtonItem = UIBarButtonItem(customView: closeButton)
            self.viewControllers.first?.navigationItem.leftBarButtonItem = closeButtonItem
        }
    }

    override open func popViewController(animated: Bool) -> UIViewController? {
        let vc = super.popViewController(animated: animated)
        self.navigationControllerDelegate?.didPopViewController(viewController: vc)
        return vc
    }

    @objc func close() {
        self.dismiss(animated: true)
    }
}

extension NavigationController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        if self.hideBackButtonText {
            let item = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            viewController.navigationItem.backBarButtonItem = item
        }
    }
}
