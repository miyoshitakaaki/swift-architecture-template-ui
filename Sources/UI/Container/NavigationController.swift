import UIKit

public final class NavigationController: UINavigationController {
    private let closeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.setTitle("✗", for: .normal)
        return button
    }()

    private let showCloseButton: Bool

    private let navigationTintColor: UIColor

    public init(
        showCloseButton: Bool = false,
        closeButtonColor: UIColor? = nil,
        navigationTintColor: UIColor = UIColor.rgba(17, 76, 190, 1)
    ) {
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        self.navigationTintColor = navigationTintColor
        super.init(nibName: nil, bundle: nil)
    }

    public init(
        rootViewController: UIViewController,
        showCloseButton: Bool = false,
        closeButtonColor: UIColor = .black,
        navigationTintColor: UIColor = UIColor.rgba(17, 76, 190, 1)
    ) {
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        self.navigationTintColor = navigationTintColor
        super.init(rootViewController: rootViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

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

    @objc func close() {
        self.dismiss(animated: true)
    }
}
