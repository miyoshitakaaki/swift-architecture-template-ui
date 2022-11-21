import Combine
import UIKit

public protocol Selection: UIView, Publisher where Output == Bool, Failure == Never {
    var isEnabled: Bool { get set }
    init(title: String, dottedLine: Bool)
    func changeButtonFlag(_ flag: Bool)
}

public final class FormSelectionView<T: Selection>: UIView {
    private let padding: UIEdgeInsets
    private let iconSize: CGFloat = 24
    private let top: CGFloat = 9
    private let bottom: CGFloat = 9

    var cancellables = Set<AnyCancellable>()

    private var itemViews = [T]()

    public lazy var multiSelectPublishers: [AnyPublisher<Bool, Never>] = itemViews
        .map { $0.eraseToAnyPublisher() }

    private lazy var checkButtonPublishers: AnyPublisher<(Int, Bool), Never> = {
        let p = itemViews.enumerated().map { index, item in
            item.map { flag in (index, flag) }.eraseToAnyPublisher()
        }
        return Publishers.MergeMany(p)
            .eraseToAnyPublisher()
            .handleEvents(receiveOutput: { [weak self] index, _ in
                if self?.singleSelect == true {
                    self?.itemViews.enumerated().filter { offset, _ in
                        index != offset
                    }.forEach { _, element in
                        element.changeButtonFlag(false)
                    }
                }
            })
            .eraseToAnyPublisher()
    }()

    private lazy var currentValue: CurrentValueSubject<(Int, Bool), Never> = .init((0, false))

    private let stackSpace: CGFloat

    private let singleSelect: Bool

    public init(stackSpace: CGFloat = 0, contents: [String], singleSelect: Bool) {
        self.stackSpace = stackSpace
        self.singleSelect = singleSelect
        self.padding = .init(top: 15, left: 0, bottom: 15, right: 0)
        super.init(frame: .zero)
        self.backgroundColor = .white
        setupView(contents)

        self.checkButtonPublishers
            .subscribe(self.currentValue).store(in: &self.cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var isEnabled = true {
        didSet {
            self.backgroundColor = self.isEnabled ? .white : UIColor.rgba(238, 238, 238, 1)

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
        let stackView: UIStackView = {
            let view: UIStackView = .init()
            view.axis = .vertical
            view.distribution = .equalSpacing
            view.alignment = .fill
            view.spacing = stackSpace
            view.backgroundColor = .clear
            return view
        }()

        addSubviews(
            stackView,
            constraints: stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        )
        contents.enumerated().forEach { index, content in
            let view: T = .init(
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
        apply(.init {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        })
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
            if flags[index] {
                currentValue.send((index, flags[index]))
            }
        }
    }
}

extension FormSelectionView: Publisher {
    public typealias Output = (Int, Bool)
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        (Int, Bool) == S.Input
    {
        self.currentValue.subscribe(subscriber)
    }
}
