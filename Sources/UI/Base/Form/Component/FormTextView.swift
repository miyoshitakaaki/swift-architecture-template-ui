import Combine
import UIKit

public final class FormTextView: UITextView, UITextViewDelegate {
    private let margin: CGFloat = 16

    private let textPublisher = CurrentValueSubject<String, Never>("")

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .placeholderText
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    public init(placeholder: String) {
        super.init(frame: .zero, textContainer: nil)
        apply(.init {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        })
        self.delegate = self
        self.heightAnchor.constraint(equalToConstant: 160).isActive = true
        self.placeholderLabel.text = placeholder
        self.isScrollEnabled = false
        self.textColor = UIColor.rgba(33, 33, 33, 1)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public var text: String? {
        didSet {
            self.placeholderLabel.isHidden = self.text?.isEmpty == false
            self.textPublisher.send(self.text ?? "")
        }
    }

    override public var isEditable: Bool {
        didSet {
            self.isSelectable = self.isEditable
            self.backgroundColor = self.isEditable ? .white : UIColor.rgba(238, 238, 238, 1)
        }
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.placeholderLabel.isHidden = !textView.text.isEmpty
        self.textPublisher.send(textView.text)
    }
}

// MARK: - private methods

private extension FormTextView {
    func setup() {
        self.addSubviews(
            self.placeholderLabel,
            constraints:
            self.placeholderLabel.topAnchor
                .constraint(equalTo: self.topAnchor, constant: self.margin),
            self.placeholderLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: self.margin
            ),
            self.placeholderLabel.trailingAnchor.constraint(
                equalTo: self.frameLayoutGuide.trailingAnchor,
                constant: -self.margin
            )
        )

        self.textContainerInset = .init(
            top: self.margin,
            left: self.margin,
            bottom: self.margin,
            right: self.margin
        )
        self.textContainer.lineFragmentPadding = 0
        self.font = .systemFont(ofSize: 16, weight: .medium)
    }
}

extension FormTextView: Publisher {
    public typealias Output = String
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        String == S.Input
    {
        self.textPublisher.subscribe(subscriber)
    }
}
