#if !os(macOS)
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

open class WebViewController: ViewController, UIGestureRecognizerDelegate, ActivityPresentable,
    AlertPresentable
{
    public var viewModel: VM!
    public var ui: UI!

    // Ref: https://stackoverflow.com/questions/71678534/swift-seturlschemehandler-causes-a-memory-leak-wkwebview
    private lazy var leakAvoider: LeakAvoider = .init(delegate: self)

    public lazy var webView: WKWebView = { [weak self] in

        guard let self else {
            return .init(frame: .zero, configuration: .init())
        }

        let config = WKWebViewConfiguration()
        if let scheme = self.scheme {
            config.setURLSchemeHandler(self.leakAvoider, forURLScheme: scheme)
        }
        config.setURLSchemeHandler(self.leakAvoider, forURLScheme: "tel")
        config.setURLSchemeHandler(self.leakAvoider, forURLScheme: "mailto")
        config.setURLSchemeHandler(self.leakAvoider, forURLScheme: "facetime")
        config.setURLSchemeHandler(self.leakAvoider, forURLScheme: "sms")
        config.setURLSchemeHandler(self.leakAvoider, forURLScheme: "maps")

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
    private var loadingObservation: NSKeyValueObservation?

    private let showProgress: Bool
    private let showLoadingIndicator: Bool
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

    private let webviewInterceptHandlers: [(handler: (_ url: URL) -> Bool, pattern: String)]

    private let needRefreshNotificationNames: [Notification.Name]

    private let noNeedAccessoryView: Bool

    private let needLocationPermissionUrls: [String]

    private let locationPermissionSuccessHandler: () -> Void

    private let locationPermissionDenyHandler: () -> Void

    /// create webview
    /// - Parameters:
    ///   - url: initial page url of webview
    ///   - localFilePath: file path for loading local html file
    ///   - showProgress: show progress indicaator
    ///   - showLoadingIndicator: show loading indicator
    ///   - prohibitPopup: for prohiviting popup from webview
    ///   - scheme: http scheme like https
    ///   - showWebBackButton: when to show back button
    ///   - javascriptEvent: javesctipt event handler
    ///   - basicAuthAccount: loginid and password ob basic authentification
    ///   - alwaysOpenSafariWhenLinkTap: always open safari or not when link is tapped
    ///   - screenNameForAnalytics: send screen name for analytics when screen show
    ///   - screenEventForAnalytics: senf event for analytics when screen show
    ///   - linkTapEventForAnalytics: send event for analytics when web page is loaded
    ///   - navigationContent: navigation bar setting
    ///   - needPullToRefresh: need pulltorefresh or not
    ///   - titleForURLPatterns: navigation bar title for url loaded
    ///   - webviewInterceptHandlers: intercept handler when will load webpage.
    ///   - needRefreshNotificationNames: reload when notification is posted
    ///   - noNeedAccessoryView: need keyboard accessory or not
    ///   - needLocationPermissionUrls: urls which webview need location permission
    ///   - locationPermissionSuccessHandler: success handler of location permission
    ///   - locationPermissionDenyHandler: deny handler of location permission
    ///   - configure: other webview setting other than above
    public init(
        url: String? = nil,
        localFilePath: String? = nil,
        showProgress: Bool = false,
        showLoadingIndicator: Bool = false,
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
        webviewInterceptHandlers: [(handler: (_ url: URL) -> Bool, pattern: String)] = [],
        needRefreshNotificationNames: [Notification.Name] = [],
        noNeedAccessoryView: Bool = false,
        needLocationPermissionUrls: [String] = [],
        locationPermissionSuccessHandler: @escaping () -> Void = {},
        locationPermissionDenyHandler: @escaping () -> Void = {},
        configure: (WKWebView) -> Void = { _ in }
    ) {
        self.url = url
        self.localFilePath = localFilePath
        self.showProgress = showProgress
        self.showLoadingIndicator = showLoadingIndicator
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
        self.webviewInterceptHandlers = webviewInterceptHandlers
        self.needRefreshNotificationNames = needRefreshNotificationNames
        self.noNeedAccessoryView = noNeedAccessoryView
        self.needLocationPermissionUrls = needLocationPermissionUrls
        self.locationPermissionSuccessHandler = locationPermissionSuccessHandler
        self.locationPermissionDenyHandler = locationPermissionDenyHandler

        super.init(nibName: nil, bundle: nil)

        configure(self.webView)
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
            self.setupProgressObservation()
        }

        if self.showLoadingIndicator {
            self.setupLoadingIndicator()
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
            let request = URLRequest(url: url)
            self.webView.load(request)
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

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        // https://hanru-yeh.medium.com/wkwebview-crashed-when-window-alert-e00255b527da
        let isVisible = self.isViewLoaded && self.view.window != nil

        if isVisible {
            self.present(title: "", message: message) { _ in
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        self.present(title: "", message: message) { _ in
            completionHandler(true)
        } cancelAction: { _ in
            completionHandler(false)
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let textField = alertController.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler("")
            }
        }
        let calcelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            _ in completionHandler(nil)
        }
        alertController.addAction(okAction)
        alertController.addAction(calcelAction)
        alertController.addTextField { $0.text = defaultText }
        present(alertController, animated: true, completion: nil)
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
    public func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        for url in self.needLocationPermissionUrls
            where webView.url?.absoluteString.contains(url) == true
        {
            LocationUtility.shared.requestPermission { [weak self] in
                self?.locationPermissionSuccessHandler()
            } deniedHandler: { [weak self] in
                self?.locationPermissionDenyHandler()
            }
        }
    }

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
                AnalyticsService.sendEvent(event)
            }

            if
                let pattern = self.webviewInterceptHandlers.first(where: { _, pattern in
                    url.absoluteString.match(pattern: pattern)
                })
            {
                let allow = pattern.handler(url)
                decisionHandler(allow ? .allow : .cancel)
            } else if self.alwaysOpenSafariWhenLinkTap, url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else if navigationAction.targetFrame == nil {
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

        self.backButton.addAction(.init(handler: { [weak self] _ in

            guard let self else { return }

            if self.webView.canGoBack {
                self.webView.goBack()
            } else {
                self.navigationController?.popViewController(animated: true)
            }

        }), for: .touchUpInside)

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

    func setupProgressObservation() {
        self.webView.topLineToSelf(self.progressView, constant: 0, height: 3)
        self.progressView.progressTintColor = UIColor.rgba(17, 76, 190, 1)
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

    func setupLoadingIndicator() {
        self.loadingObservation = self.webView
            .observe(\.isLoading, options: .new) { [weak self] _, change in

                guard let self else { return }

                let isPullToRefreshing = self.webView.scrollView.refreshControl?.isRefreshing

                if change.newValue == true, isPullToRefreshing != true {
                    self.presentActivity()
                } else {
                    self.dismissActivity()
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

            if let newClass {
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

class LeakAvoider: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        self.delegate?.webView(webView, start: urlSchemeTask)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        self.delegate?.webView(webView, stop: urlSchemeTask)
    }

    weak var delegate: WKURLSchemeHandler?

    init(delegate: WKURLSchemeHandler) {
        self.delegate = delegate
        super.init()
    }
}
#endif
