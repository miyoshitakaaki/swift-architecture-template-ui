import Combine
import UIKit

extension ViewStyle where T: UILabel {
    static var darkGlay97SmallSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIConfig.darkGlay97
            $0.font = UIFont.systemFont(ofSize: 12)
        }
    }
}

final class FormSelectionItemView: UIView {
    private let iconSize: CGFloat = 24
    private let top: CGFloat = 9
    private let bottom: CGFloat = 9

    private let togglePublisher = CurrentValueSubject<Bool, Never>(false)

    init(title: String, dottedLine: Bool) {
        super.init(frame: .zero)
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(toggleButtonFromView(_:))
        )
        self.addGestureRecognizer(tapGestureRecognizer)
        self.backgroundColor = .white
        setupView(title: title)
        line(dottedLine: dottedLine)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isEnabled = true {
        didSet {
            self.backgroundColor = self.isEnabled ? .white : UIConfig.lightGray_200
        }
    }
}

private extension FormSelectionItemView {
    func line(dottedLine: Bool) {
        if dottedLine {
            let dottedLineView: DottedLineView = .init()
            dottedLineView.backgroundColor = .white
            self.addSubviews(
                dottedLineView,
                constraints: dottedLineView.trailingAnchor
                    .constraint(equalTo: self.trailingAnchor),
                dottedLineView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                dottedLineView.heightAnchor.constraint(equalToConstant: 1),
                dottedLineView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1)
            )
        }
    }

    func setupView(title: String) {
        let label: UILabel = .init(style: .darkGlay97SmallSize, title: title)
        self.addSubviews(
            label,
            constraints: label.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: 15
            ),
            label.heightAnchor.constraint(equalToConstant: self.iconSize),
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: self.top),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.bottom)
        )

        let button: CheckMarkButton = .init()
        button.backgroundColor = .clear
        button.onBackGroundColor = UIConfig.accentBlue
        button.offBackGroundColor = UIConfig.darkGray_400
        button.addTarget(self, action: #selector(self.toggle), for: .touchUpInside)
        self.addSubviews(
            button,
            constraints: button.trailingAnchor
                .constraint(equalTo: self.trailingAnchor, constant: -11),
            button.heightAnchor.constraint(equalToConstant: self.iconSize),
            button.widthAnchor.constraint(equalToConstant: self.iconSize),
            button.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.bottom)
        )
    }

    /// toggle
    ///
    ///  チェックマークのオンオフ
    @objc private func toggle(_ sender: CheckMarkButton) {
        guard self.isEnabled else { return }
        sender.toggle()
        self.togglePublisher.send(sender.checkFlag)
    }

    @objc private func toggleButtonFromView(_ sender: UITapGestureRecognizer) {
        sender.view?.subviews.forEach { view in
            if let button = view as? CheckMarkButton {
                button.toggle()
                togglePublisher.send(button.checkFlag)
            }
        }
    }
}

// MARK: - public method

extension FormSelectionItemView {
    func changeButtonFlag(_ flag: Bool) {
        self.subviews.forEach { view in
            if let button = view as? CheckMarkButton {
                button.checkFlag = flag
                button.setNeedsDisplay()
                togglePublisher.send(button.checkFlag)
            }
        }
    }
}

extension FormSelectionItemView: Publisher {
    typealias Output = Bool
    typealias Failure = Never

    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Bool == S.Input {
        self.togglePublisher.subscribe(subscriber)
    }
}
