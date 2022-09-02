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

    public lazy var checkButtonPublishers: AnyPublisher<(Int, Bool), Never> = {
        let p = itemViews.enumerated().map { index, item in
            item.map { flag in (index, flag) }.eraseToAnyPublisher()
        }
        return Publishers.MergeMany(p)
            .eraseToAnyPublisher()
            .handleEvents(receiveOutput: { index, _ in
                if self.singleSelect {
                    self.itemViews.enumerated().filter { offset, _ in
                        index != offset
                    }.forEach { _, element in
                        element.changeButtonFlag(false)
                    }
                }
            })
            .eraseToAnyPublisher()
    }()

    private let stackSpace: CGFloat

    private let singleSelect: Bool

    public init(stackSpace: CGFloat = 0, contents: [String], singleSelect: Bool) {
        self.stackSpace = stackSpace
        self.singleSelect = singleSelect
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
        }
    }
}
