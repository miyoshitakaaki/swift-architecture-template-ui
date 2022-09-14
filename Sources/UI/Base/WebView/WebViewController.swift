import Combine
import UIKit
import WebKit

public struct JavascriptEvent {
    let name: String
    let handler: (WKScriptMessage) -> Void

    public init(
        name: String,
        handler: @escaping (WKScriptMessage) -> Void
    ) {
        self.name = name
        self.handler = handler
    }
}

extension WebViewController: VCInjectable {
    public typealias VM = NoViewModel
    public typealias UI = NoUserInterface
}

// MARK: - stored properties

open class WebViewController: UIViewController {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        if let scheme = self.scheme {
            config.setURLSchemeHandler(self, forURLScheme: scheme)
        }

        let userContentController = WKUserContentController()
        self.javascriptEvent.forEach { event in
            userContentController.add(self, name: event.name)
        }
        config.userContentController = userContentController

        config.allowsInlineMediaPlayback = true
        return .init(frame: .zero, configuration: config)

    }()

    private let url: String?
    private let localFilePath: String?

    private let backButton = UIButton(style: .init(style: { button in
        button.setBackgroundImage(UIImage(systemName: "chevron.backward"), for: .normal)
    }))

    private var canGobackObservation: NSKeyValueObservation?

    private let progressView: UIProgressView = .init(frame: .zero)
    private var observation: NSKeyValueObservation?

    private let showProgress: Bool
    private let prohibitPopup: Bool
    private let scheme: String?
    private let showWebBackButton: Bool
    private let javascriptEvent: [JavascriptEvent]

    public init(
        url: String? = nil,
        localFilePath: String? = nil,
        screenTitle: String,
        showProgress: Bool = false,
        prohibitPopup: Bool = true,
        scheme: String? = nil,
        showWebBackButton: Bool = false,
        javascriptEvent: [JavascriptEvent] = []
    ) {
        self.url = url
        self.localFilePath = localFilePath
        self.showProgress = showProgress
        self.prohibitPopup = prohibitPopup
        self.scheme = scheme
        self.showWebBackButton = showWebBackButton
        self.javascriptEvent = javascriptEvent

        super.init(nibName: nil, bundle: nil)
        self.title = screenTitle
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - override methods

public extension WebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubviews(
            self.webView,
            constraints:
            self.webView.leadingAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.webView.trailingAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.webView.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        )

        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true

        if self.showProgress {
            self.setupObservation()
        }

        if self.showWebBackButton {
            self.setupBackButton()
            self.setupCanGobackObservation()
        }

        if let localFilePath = self.localFilePath {
            let localHTMLUrl = URL(fileURLWithPath: localFilePath, isDirectory: false)
            self.webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
        } else if let url = self.url {
            self.webView.load(URLRequest(url: URL(string: url)!))
        }
    }
}

extension WebViewController: WKUIDelegate {}

extension WebViewController: WKURLSchemeHandler {
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        UIApplication.shared.open(webView.url!)
        urlSchemeTask.didReceive(URLResponse())
        urlSchemeTask.didReceive(Data())
        urlSchemeTask.didFinish()
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didFinish()
    }
}

extension WebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.prohibitPopup {
            self.prohibitTouchCalloutAndUserSelect()
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        self.javascriptEvent.first { event in
            event.name == message.name
        }?.handler(message)
    }
}

private extension WebViewController {
    func setupBackButton() {
        self.backButton.isHidden = true
        if #available(iOS 14.0, *) {
            self.backButton.addAction(.init(handler: { [weak self] _ in
                self?.webView.goBack()
            }), for: .touchUpInside)
        } else {
            // Fallback on earlier versions
        }
        let backItem = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = backItem
    }

    func setupCanGobackObservation() {
        self.canGobackObservation = self.webView.observe(\.canGoBack, options: .new) { _, _ in
            self.backButton.isHidden = !self.webView.canGoBack
        }
    }

    /// 長押しによる選択、コールアウト表示を禁止する
    func prohibitTouchCalloutAndUserSelect() {
        let script = """
        var css = '*{-webkit-touch-callout:none;-webkit-user-select:none}';
        var head = document.head || document.getElementsByTagName('head')[0];
        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode(css));
        head.appendChild(style);
        """
        self.webView.evaluateJavaScript(script, completionHandler: nil)
    }

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
