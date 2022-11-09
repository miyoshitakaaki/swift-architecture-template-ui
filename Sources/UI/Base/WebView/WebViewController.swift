import Combine
import UIKit
import Utility
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

open class WebViewController: ViewController, UIGestureRecognizerDelegate {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public lazy var webView: WKWebView = { [weak self] in

        guard let self else {
            return .init(frame: .zero, configuration: .init())
        }

        let config = WKWebViewConfiguration()
        if let scheme = self.scheme {
            config.setURLSchemeHandler(self, forURLScheme: scheme)
        }
        config.setURLSchemeHandler(self, forURLScheme: "tel")
        config.setURLSchemeHandler(self, forURLScheme: "mailto")
        config.setURLSchemeHandler(self, forURLScheme: "facetime")
        config.setURLSchemeHandler(self, forURLScheme: "sms")
        config.setURLSchemeHandler(self, forURLScheme: "maps")

        let userContentController = WKUserContentController()
        self.javascriptEvent.forEach { event in
            userContentController.add(self, name: event.name)
        }
        config.userContentController = userContentController
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        return .init(frame: .zero, configuration: config)

    }()

    private let url: String?
    private let localFilePath: String?

    private let backButton = UIButton(style: .init(style: { button in
        let largeConfig = UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold,
            scale: .large
        )
        button.setImage(
            UIImage(
                systemName: "chevron.backward",
                withConfiguration: largeConfig
            ),
            for: .normal
        )
        button.contentEdgeInsets = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 8,
            right: 32
        )
    }))

    private var canGobackObservation: NSKeyValueObservation?
    private var curentPageObservation: NSKeyValueObservation?

    private let progressView: UIProgressView = .init(frame: .zero)
    private var observation: NSKeyValueObservation?

    private let showProgress: Bool
    private let prohibitPopup: Bool
    private let scheme: String?
    private let showWebBackButton: ShowWebBackButton
    private let javascriptEvent: [JavascriptEvent]

    private var needReflesh = false
    private let basicAuthAccount: (id: String, password: String)?
    private let alwaysOpenSafariWhenLinkTap: Bool

    public enum ShowWebBackButton {
        case always, whenHasHistory
    }

    private let _screenNameForAnalytics: [AnalyticsScreen]

    private let _screenEventForAnalytics: [AnalyticsEvent]

    override open var screenNameForAnalytics: [AnalyticsScreen] { self._screenNameForAnalytics }

    override open var screenEventForAnalytics: [AnalyticsEvent] { self._screenEventForAnalytics }

    private let linkTapEventForAnalytics: ((_ url: String) -> AnalyticsEvent)?

    private let navigationContent: NavigationContent

    private let needPullToRefresh: Bool

    private let titleForURLPatterns: [(title: String, pattern: String)]

    private let needRefreshNotificationNames: [Notification.Name]

    private let noNeedAccessoryView: Bool

    public init(
        url: String? = nil,
        localFilePath: String? = nil,
        showProgress: Bool = false,
        prohibitPopup: Bool = true,
        scheme: String? = nil,
        showWebBackButton: ShowWebBackButton = .always,
        javascriptEvent: [JavascriptEvent] = [],
        basicAuthAccount: (id: String, password: String)? = nil,
        alwaysOpenSafariWhenLinkTap: Bool = false,
        screenNameForAnalytics: [AnalyticsScreen] = [],
        screenEventForAnalytics: [AnalyticsEvent] = [],
        linkTapEventForAnalytics: ((_ url: String) -> AnalyticsEvent)? = nil,
        navigationContent: NavigationContent,
        needPullToRefresh: Bool = false,
        titleForURLPatterns: [(title: String, pattern: String)] = [],
        needRefreshNotificationNames: [Notification.Name] = [],
        noNeedAccessoryView: Bool = false
    ) {
        self.url = url
        self.localFilePath = localFilePath
        self.showProgress = showProgress
        self.prohibitPopup = prohibitPopup
        self.scheme = scheme
        self.showWebBackButton = showWebBackButton
        self.javascriptEvent = javascriptEvent
        self.basicAuthAccount = basicAuthAccount
        self.alwaysOpenSafariWhenLinkTap = alwaysOpenSafariWhenLinkTap
        self._screenNameForAnalytics = screenNameForAnalytics
        self._screenEventForAnalytics = screenEventForAnalytics
        self.linkTapEventForAnalytics = linkTapEventForAnalytics
        self.navigationContent = navigationContent
        self.needPullToRefresh = needPullToRefresh
        self.titleForURLPatterns = titleForURLPatterns
        self.needRefreshNotificationNames = needRefreshNotificationNames
        self.noNeedAccessoryView = noNeedAccessoryView

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar(content: self.navigationContent)

        self.view.addSubviews(
            self.webView,
            constraints:
            self.webView.leadingAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.webView.trailingAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.webView.bottomAnchor.constraint(
                equalTo: self.tabBarController == nil
                    ? self.view.bottomAnchor
                    : self.view.safeAreaLayoutGuide.bottomAnchor
            )
        )

        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true

        if self.noNeedAccessoryView {
            self.removeAccessoryView()
        }

        if self.showProgress {
            self.setupObservation()
        }

        if self.needPullToRefresh {
            self.setupRefreshControl()
        }

        self.setupBackButton()
        self.setupCanGobackObservation()
        self.setupCurentPageObservation()

        self.addObserver()

        self.load()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.needReflesh {
            self.webView.reload()
            self.needReflesh = false
        }
    }

    override open func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        super.presentationControllerDidDismiss(presentationController)

        if self.needReflesh {
            self.webView.reload()
            self.needReflesh = false
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    private func addObserver() {
        self.needRefreshNotificationNames.forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .current
            ) { [weak self] _ in
                self?.needReflesh = true
            }
        }
    }
}

private extension WebViewController {
    func load() {
        if let localFilePath = self.localFilePath {
            let localHTMLUrl = URL(fileURLWithPath: localFilePath, isDirectory: false)
            self.webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
        } else if
            let urlString = self.url,
            let url = URL(string: urlString)
        {
            self.webView.load(URLRequest(url: url))
        }
    }
}

extension WebViewController: WKUIDelegate {
    @available(iOS 15.0, *)
    public func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        .grant
    }
}

extension WebViewController: WKURLSchemeHandler {
    open func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        UIApplication.shared.open(webView.url!)
        urlSchemeTask.didReceive(URLResponse())
        urlSchemeTask.didReceive(Data())
        urlSchemeTask.didFinish()
    }

    open func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didFinish()
    }
}

extension WebViewController: WKNavigationDelegate {
    open func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        switch navigationAction.navigationType {
        case .linkActivated:
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if let event = self.linkTapEventForAnalytics?(url.absoluteString) {
                AnalyticsService.shared.sendEvent(event)
            }

            if self.alwaysOpenSafariWhenLinkTap, url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        default:
            decisionHandler(.allow)
        }
    }

    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.scrollView.refreshControl?.endRefreshing()

        if self.prohibitPopup, #available(iOS 16.0, *) {
            self.prohibitTouchCalloutAndUserSelect()
        }
    }

    open func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let basicAuthAccount = self.basicAuthAccount {
            switch challenge.protectionSpace.authenticationMethod {
            case NSURLAuthenticationMethodHTTPBasic:
                let credential = URLCredential(
                    user: basicAuthAccount.id,
                    password: basicAuthAccount.password,
                    persistence: URLCredential.Persistence.forSession
                )
                completionHandler(.useCredential, credential)

            default:
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    open func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        self.javascriptEvent.first { event in
            event.name == message.name
        }?.handler(message)
    }
}

private extension WebViewController {
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        self.webView.scrollView.refreshControl = refreshControl
        refreshControl.addTarget(
            self,
            action: #selector(self.refreshWebView(sender:)),
            for: .valueChanged
        )
    }

    @objc func refreshWebView(sender: UIRefreshControl) {
        self.webView.reload()
    }

    func setupBackButton() {
        self.backButton.isHidden = self.showWebBackButton == .whenHasHistory

        if #available(iOS 14.0, *) {
            self.backButton.addAction(.init(handler: { [weak self] _ in

                guard let self = self else { return }

                if self.webView.canGoBack {
                    self.webView.goBack()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }

            }), for: .touchUpInside)
        } else {
            // Fallback on earlier versions
        }
        let backItem = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = backItem
    }

    func setupCanGobackObservation() {
        self.canGobackObservation = self.webView
            .observe(\.canGoBack, options: .new) { [weak self] _, _ in

                guard let self else { return }

                switch self.showWebBackButton {
                case .always:
                    self.backButton.isHidden = false

                case .whenHasHistory:
                    self.backButton.isHidden = !self.webView.canGoBack
                }

                self.navigationController?.interactivePopGestureRecognizer?
                    .isEnabled = !self.webView.canGoBack
            }
    }

    func setupCurentPageObservation() {
        self.curentPageObservation = self.webView.observe(
            \.url,
            options: .new,
            changeHandler: { [weak self] _, keyValueObject in

                guard let self else { return }

                if let newValue: URL = keyValueObject.newValue?.map({ $0 }) {
                    let title = self.titleForURLPatterns.first { _, pattern in
                        newValue.absoluteString.match(pattern: pattern)
                    }?.title

                    if let title {
                        DispatchQueue.main.async {
                            if let label = self.navigationItem.titleView as? UILabel {
                                label.text = title
                                label.sizeToFit()
                            }
                        }
                    }
                }
            }
        )
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
        self.observation = self.webView
            .observe(\.estimatedProgress, options: .new) { [weak self] _, change in

                guard let self else { return }

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

    // Ref: https://qiita.com/rokubay/items/e25936a35b4ad47d1447
    func removeAccessoryView() {
        guard
            let target = self.webView.scrollView.subviews.first(where: {
                String(describing: type(of: $0)).hasPrefix("WKContent")
            }), let superclass = target.superclass
        else {
            return
        }

        let noInputAccessoryViewClassName = "\(superclass)_NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)

        if
            newClass == nil, let targetClass = object_getClass(target),
            let classNameCString = noInputAccessoryViewClassName.cString(using: .ascii)
        {
            newClass = objc_allocateClassPair(targetClass, classNameCString, 0)

            if let newClass = newClass {
                objc_registerClassPair(newClass)
            }
        }

        guard
            let noInputAccessoryClass = newClass, let originalMethod = class_getInstanceMethod(
                NoInputAccessoryView.self,
                #selector(getter: NoInputAccessoryView.inputAccessoryView)
            )
        else {
            return
        }
        class_addMethod(
            noInputAccessoryClass.self,
            #selector(getter: NoInputAccessoryView.inputAccessoryView),
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
        object_setClass(target, noInputAccessoryClass)
    }
}

private final class NoInputAccessoryView: NSObject {
    @objc var inputAccessoryView: AnyObject? { nil }
}
