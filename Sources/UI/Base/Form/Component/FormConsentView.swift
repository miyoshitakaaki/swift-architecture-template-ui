#if !os(macOS)
import Combine
import UIKit

public protocol FormConsentViewDelegate: AnyObject {
    func privacy()
    func terms()
}

public final class FormConsentView: UIView {
    private let formTextView: LinkTextView
    private let delegate: FormConsentViewDelegate?

    private let agreeButton: CheckMarkButton

    public let checkPublisher = CurrentValueSubject<Bool, Never>(false)

    public init(
        formTextView: LinkTextView,
        agreeButton: CheckMarkButton,
        text: String = "プライバシーポリシー・利用規約への同意",
        delegate: FormConsentViewDelegate? = nil
    ) {
        self.formTextView = formTextView
        self.agreeButton = agreeButton
        self.delegate = delegate
        super.init(frame: .infinite)
        self.setupLayout()
        self.textAttributedText(text: text)

        agreeButton.addTarget(self, action: #selector(self.toggle), for: .touchUpInside)
    }

    /// toggle
    ///
    ///  同意チェックマークのオンオフ
    @objc private func toggle() {
        self.agreeButton.toggle()
        self.checkPublisher.value.toggle()
    }

    /// textAttributedText
    ///
    /// プライバシーポリシーと利用規約のリンク設定
    private func textAttributedText(text: String) {
        let stringAttributes: [NSAttributedString.Key: Any] = [:]
        let attributedString = NSMutableAttributedString(string: text, attributes: stringAttributes)
        let privacyRange = NSString(string: text).range(of: "プライバシーポリシー")
        attributedString.addAttribute(
            NSAttributedString.Key.link,
            value: "https://privacy",
            range: privacyRange
        )
        let termsRange = NSString(string: text).range(of: "利用規約")
        attributedString.addAttribute(
            NSAttributedString.Key.link,
            value: "https://terms",
            range: termsRange
        )
        self.formTextView.backgroundColor = .clear
        self.formTextView.isEditable = false
        self.formTextView.isScrollEnabled = false
        self.formTextView
            .linkTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.rgba(17, 76, 190, 1)]
        self.formTextView.attributedText = attributedString
        self.formTextView.delegate = self
    }

    private func setupLayout() {
        self.addSubviews(
            self.agreeButton,
            constraints:
            self.agreeButton.topAnchor.constraint(
                equalTo: self.topAnchor
            ),
            self.agreeButton.bottomAnchor.constraint(
                equalTo: self.bottomAnchor
            ),
            self.agreeButton.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            self.agreeButton.heightAnchor
                .constraint(equalToConstant: 24),
            self.agreeButton.widthAnchor
                .constraint(equalToConstant: 24)
        )
        self.addSubviews(
            self.formTextView,
            constraints:
            self.formTextView.topAnchor.constraint(equalTo: self.topAnchor),
            self.formTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.formTextView.leadingAnchor.constraint(
                equalTo: self.agreeButton.trailingAnchor,
                constant: 3
            ),
            self.formTextView.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension FormConsentView {
    func agreeButtonBackGroundColorGlay() {
        self.agreeButton.offBackGroundColor = UIColor.rgba(245, 245, 245, 1)
    }

    func changeCheckButton(_ isOn: Bool) {
        self.agreeButton.checkFlag = isOn
        self.agreeButton.setNeedsDisplay()
        self.checkPublisher.value = isOn
    }
}

extension FormConsentView: UITextViewDelegate {
    public func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard let delegate = self.delegate else { return true }
        let urlString = URL.absoluteString
        if urlString == "https://privacy" {
            delegate.privacy()
            return false
        } else if urlString == "https://terms" {
            delegate.terms()
            return false
        }
        return true
    }
}

extension FormConsentView: Publisher {
    public typealias Output = Bool
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Bool == S.Input {
        self.checkPublisher.subscribe(subscriber)
    }
}
#endif
