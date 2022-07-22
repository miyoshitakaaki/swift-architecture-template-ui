import Combine
import UIKit

open class NavigationController: UINavigationController {
    private let closeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.setTitle("✗", for: .normal)
        return button
    }()

    /// 閉じるボタンのイベント通知用
    /// storeをFlowControllerのself.cancellableで実装するとまずい場合がある
    /// 例)pushViewControllerを行うNavigationControllerだと別画面の閉じるイベントが通知される可能性がある
    /// そのときはView側にcancellableを作成する必要がある
    public lazy var didTapCloseButtonPublisher: PassthroughSubject<Void, Never> = .init()

    private let hideBackButtonText: Bool

    private let showCloseButton: Bool

    private let navigationTintColor: UIColor

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

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // モーダル表示で全画面表示しなかったときプルダウンで閉じる
        // close() でイベントを発行すると重複するためviewWillDisappearで統一
        if self.isBeingDismissed {
            didTapCloseButtonPublisher.send()
        }
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
