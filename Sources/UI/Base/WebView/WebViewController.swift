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
    private let url: String?
    private let localFilePath: String?

    public init(url: String? = nil, localFilePath: String? = nil, screenTitle: String) {
        self.url = url
        self.localFilePath = localFilePath

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

        if let localFilePath = self.localFilePath {
            let localHTMLUrl = URL(fileURLWithPath: localFilePath, isDirectory: false)
            self.webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
        } else if let url = self.url {
            self.webView.load(URLRequest(url: URL(string: url)!))
        }
    }
}
