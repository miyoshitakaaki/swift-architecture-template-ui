import Combine
import UIKit
import WebKit

extension WebViewController: VCInjectable {
    public typealias VM = NoViewModel
    public typealias UI = NoUserInterface
}

// MARK: - stored properties

public final class WebViewController: UIViewController {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    private let webView: ProgressWebView = .init(frame: .zero)
    private let url: String

    /// 画面を閉じる時に呼ばれる
    /// 戻るボタンのイベントとして扱う 閉じるボタンは拾えない
    public let willDismissFromParent: PassthroughSubject<Void, Never> = .init()

    public init(url: String, screenTitle: String) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        self.title = screenTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - override methods

public extension WebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.edgeToSelf(self.webView)
        self.webView.setupObservation()
        self.webView.load(URLRequest(url: URL(string: self.url)!))
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false

        if self.isMovingFromParent {
            self.willDismissFromParent.send(())
        }
    }
}

extension WebViewController {}
