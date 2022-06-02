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
}

extension WebViewController {}
