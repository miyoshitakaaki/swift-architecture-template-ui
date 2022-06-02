import WebKit

public final class ProgressWebView: WKWebView {
    private let progressView: UIProgressView = .init(frame: .zero)
    private var observation: NSKeyValueObservation?

    public func setupObservation() {
        self.topLineToSelf(self.progressView, constant: 0, height: 3)
        self.progressView.progressTintColor = UIConfig.accentBlue
        self.observation = self.observe(\.estimatedProgress, options: .new) { _, change in
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
