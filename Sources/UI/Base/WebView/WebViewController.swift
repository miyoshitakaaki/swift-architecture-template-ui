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

    private let webView: WKWebView = .init(frame: .zero)
    private let url: String?
    private let localFilePath: String?

    private let progressView: UIProgressView = .init(frame: .zero)
    private var observation: NSKeyValueObservation?

    private let showProgress: Bool

    public init(
        url: String? = nil,
        localFilePath: String? = nil,
        screenTitle: String,
        showProgress: Bool = false
    ) {
        self.url = url
        self.localFilePath = localFilePath
        self.showProgress = showProgress

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

        if self.showProgress {
            self.setupObservation()
        }

        if let localFilePath = self.localFilePath {
            let localHTMLUrl = URL(fileURLWithPath: localFilePath, isDirectory: false)
            self.webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
        } else if let url = self.url {
            self.webView.load(URLRequest(url: URL(string: url)!))
        }
    }
}

private extension WebViewController {
    func setupObservation() {
        self.webView.topLineToSelf(self.progressView, constant: 0, height: 3)
        self.progressView.progressTintColor = UIConfig.accentBlue
        self.observation = self.webView.observe(\.estimatedProgress, options: .new) { _, change in
            self.progressView.setProgress(Float(change.newValue!), animated: true)
            if change.newValue! >= 1.0 {
                UIView.animate(
                    withDuration: 1.0,
                    delay: 0.0,
                    options: [.curveEaseIn],
                    animations: {
                        self.progressView.alpha = 0.0
                    },
                    completion: { (_: Bool) in
                        self.progressView.setProgress(0, animated: false)
                    }
                )
            } else {
                self.progressView.alpha = 1.0
            }
        }
    }
}
