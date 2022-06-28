import UIKit

public final class NavigationController: UINavigationController {
    private let closeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.setTitle("✗", for: .normal)
        return button
    }()

    private let showCloseButton: Bool

    public init(
        showCloseButton: Bool = false,
        closeButtonColor: UIColor? = nil
    ) {
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        super.init(nibName: nil, bundle: nil)
    }

    public init(
        rootViewController: UIViewController,
        showCloseButton: Bool = false,
        closeButtonColor: UIColor = .black
    ) {
        self.showCloseButton = showCloseButton
        self.closeButton.setTitleColor(closeButtonColor, for: .normal)
        super.init(rootViewController: rootViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.tintColor = UIConfig.accentBlue
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
