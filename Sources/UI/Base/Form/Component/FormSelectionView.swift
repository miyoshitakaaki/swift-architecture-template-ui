import Combine
import UIKit

extension ViewStyle where T: UIView {
    static var cornerRadius: ViewStyle<T> {
        ViewStyle<T> {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        }
    }
}

public final class FormSelectionView: UIView {
    private let padding: UIEdgeInsets
    private let iconSize: CGFloat = 24
    private let top: CGFloat = 9
    private let bottom: CGFloat = 9

    var cancellables = Set<AnyCancellable>()

    private let textPublisher = CurrentValueSubject<String, Never>("")
    private var itemViews = [FormSelectionItemView]()

    public lazy var checkButtonPublishers: [AnyPublisher<Bool, Never>] = itemViews
        .map { $0.eraseToAnyPublisher() }

    public init(contents: [String]) {
        self.padding = .init(top: 15, left: 0, bottom: 15, right: 0)
        super.init(frame: .zero)
        self.backgroundColor = .white
        setupView(contents)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var isEnabled = true {
        didSet {
            self.backgroundColor = self.isEnabled ? .white : UIConfig.lightGray_200

            self.itemViews.forEach { view in
                view.isEnabled = self.isEnabled
                view.isUserInteractionEnabled = self.isEnabled
            }
        }
    }
}

private extension FormSelectionView {
    /// 選択肢の追加
    func setupView(_ contents: [String]) {
        heightAnchor
            .constraint(
                equalToConstant: CGFloat(contents.count) *
                    (self.iconSize + self.top + self.bottom) + 30
            ).isActive = true

        let stackView: UIStackView = {
            let view: UIStackView = .init()
            view.axis = .vertical
            view.distribution = .equalSpacing
            view.alignment = .fill
            view.spacing = 0
            view.backgroundColor = .clear
            return view
        }()

        addSubviews(
            stackView,
            constraints: stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        )
        contents.enumerated().forEach { index, content in
            let view: FormSelectionItemView = .init(
                title: content,
                dottedLine: index < contents.count - 1
            )
            stackView.addArrangedSubviews(
                view,
                constraints: view.widthAnchor
                    .constraint(equalTo: stackView.widthAnchor)
            )
            view.tag = index
            self.itemViews.append(view)
        }
        apply(.cornerRadius)
    }
}

// MARK: - public method

public extension FormSelectionView {
    func updateFlagOutSide(flags: [Bool]) {
        if flags.count != self.itemViews.count {
            return
        }
        self.itemViews.enumerated().forEach { index, view in
            view.changeButtonFlag(flags[index])
        }
    }
}

extension FormSelectionView: Publisher {
    public typealias Output = String
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        String == S.Input
    {
        self.textPublisher.subscribe(subscriber)
    }
}
