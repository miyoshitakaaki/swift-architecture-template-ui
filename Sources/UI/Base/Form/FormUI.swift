import Combine
import UIKit

public final class FormUI {
    private let scrollView: ScrollView

    private let bottomFixedView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private let completionButton: UIButton
    private let hideCompletionButton: Bool

    private let form: FormUIProtocol

    lazy var completionButtonPublisher: AnyPublisher<UIButton, Never> = completionButton
        .publisher(for: .touchUpInside).eraseToAnyPublisher()

    public init(
        form: FormUIProtocol,
        hideCompletionButton: Bool = false
    ) {
        self.scrollView = .init(style: .init {
            $0.showsVerticalScrollIndicator = false
            $0.scrollRectToVisible($0.frame, animated: true)
            $0.backgroundColor = .clear
        })
        self.form = form
        self.completionButton = .init(
            style: form.completionButtonPotition == .top
                ? form.completionButtonPotitionTopStyle
                : form.completionButtonPotitionBottomStyle,
            title: form.isOptional ? form.optionalButtonTitle : form.completionButtonTitle
        )
        self.hideCompletionButton = hideCompletionButton
        self.completionButton.isHidden = hideCompletionButton
        self.bottomFixedView.isHidden = hideCompletionButton
    }

    func enableCompleteButton(enable: Bool) {
        self.completionButton.isEnabled = enable || self.form.showInvalidAlert
        self.completionButton.isUserInteractionEnabled = enable || self.form.showInvalidAlert

        if self.form.completionButtonPotition == .top {
            self.completionButton.apply(enable ? .init {
                $0.setTitleColor(UIColor.rgba(17, 76, 190, 1), for: .normal)
            } : .init {
                $0.setTitleColor(UIColor.rgba(117, 117, 117, 1), for: .normal)
            })
        } else {
            self.completionButton.apply(
                enable
                    ? self.form.bottomCompletionButtonEnableBackgroundStyle
                    : self.form.bottomCompletionButtondisableBackgroundStyle
            )
        }
    }

    func bindCompleteButton() -> AnyCancellable {
        self.form.isValid.sink { [weak self] isValid in
            self?.enableCompleteButton(enable: isValid)
        }
    }

    func chanegCompleteButtonTitleIfNeeded(isEmpty: Bool) {
        guard self.form.isOptional else { return }

        if isEmpty {
            self.completionButton.setTitle(self.form.optionalButtonTitle, for: .normal)
        } else {
            self.completionButton.setTitle(self.form.completionButtonTitle, for: .normal)
        }
    }

    @objc func nextButtonTapped(_ sender: UIButton) {
        self.form.focusNextResponder()
    }
}

extension FormUI: UserInterface {
    public func setupView(rootview: UIView) {
        rootview.backgroundColor = self.form.backgroundColor

        switch self.form.completionButtonPotition {
        case .top:
            self.inScrollView(rootview)
            self.inStackView()
            self.form.views.forEach(addStackView)
        case let .bottom(width):
            self.inScrollView(rootview)
            self.inStackView()
            self.form.views.forEach(addStackView)
            self.setupCompletionButton(width: width)
        case .bottomFix:
            self.setupFixedCompletionButton(rootview: rootview)
            self.inScrollView(rootview)
            self.inStackView()
            self.form.views.forEach(addStackView)
        }

        setupInputAccessoryView(rootview)
        self.enableCompleteButton(enable: false)
    }

    public func setupNavigationBar(
        navigationBar: UINavigationBar?,
        navigationItem: UINavigationItem?
    ) {
        guard let navigationItem = navigationItem else { return }

        if self.form.completionButtonPotition == .top {
            setupRightBarButtonItem(navigationItem: navigationItem)
        }

        if let view = self.form.titleView {
            navigationItem.titleView = view
        }
    }
}

private extension FormUI {
    private func setupInputAccessoryView(_ rootview: UIView) {
        let keyboardFrameTrackerView: AMKeyboardFrameTrackerView = .init(
            height: self.form.showAccessoryView ? 44 : 0
        )
        keyboardFrameTrackerView.isUserInteractionEnabled = true
        keyboardFrameTrackerView.isHidden = !self.form.showAccessoryView

        let button: UIButton = .init(style: .init {
            $0.setTitleColor(UIColor.rgba(17, 76, 190, 1), for: .normal)
        }, title: "次へ")
        button.addTarget(self, action: #selector(self.nextButtonTapped(_:)), for: .touchUpInside)

        let barButtonItem: UIBarButtonItem = .init(customView: button)

        let toolbar: UIToolbar = .init()
        toolbar.items = [barButtonItem]
        keyboardFrameTrackerView.edgeToSelf(toolbar)

        keyboardFrameTrackerView.onKeyboardFrameDidChange = { [weak self, weak rootview] rect in
            guard let self = self, let rootview = rootview else { return }

            self.scrollView.findConstraint(layoutAttribute: .bottom)?.isActive = false

            let top = (rootview.window?.frame.height ?? 0)
                - self.form.completionButtonPotition.bottomFixedViewHeight
                - rect.origin.y

            if top > self.form.completionButtonPotition.bottomFixedViewHeight {
                self.scrollView.bottomAnchor.constraint(
                    equalTo: rootview.bottomAnchor,
                    constant: -(top + self.form.completionButtonPotition.bottomFixedViewHeight)
                ).isActive = true
            } else {
                let bottomAndhor = self.form.completionButtonPotition == .bottomFix
                    ? self.bottomFixedView.topAnchor
                    : rootview.bottomAnchor

                self.scrollView.bottomAnchor.constraint(
                    equalTo: bottomAndhor
                ).isActive = true
            }

            rootview.layoutIfNeeded()
        }

        self.form.set(inputAccessoryView: keyboardFrameTrackerView)
    }

    private func inScrollView(_ rootview: UIView) {
        self.scrollView.keyboardDismissMode = .interactive
        self.scrollView.contentInset.bottom = 16

        let bottomAndhor = self.form.completionButtonPotition == .bottomFix
            ? self.bottomFixedView.topAnchor
            : rootview.bottomAnchor

        rootview.addSubviews(
            self.scrollView,
            constraints:
            self.scrollView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor),
            self.scrollView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.scrollView.bottomAnchor
                .constraint(equalTo: bottomAndhor)
        )
    }

    private func inStackView() {
        self.scrollView.addSubviews(
            self.verticalStackView,
            constraints:
            self.verticalStackView.leadingAnchor
                .constraint(equalTo: self.scrollView.leadingAnchor),
            self.verticalStackView.trailingAnchor
                .constraint(equalTo: self.scrollView.trailingAnchor),
            self.verticalStackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.verticalStackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.verticalStackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor)
        )
    }

    private func addStackView(_ view: UIView) {
        self.verticalStackView.addArrangedSubviews(
            view,
            constraints:
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 32)
        )
    }

    private func setupCompletionButton(width: CGFloat) {
        self.verticalStackView.addArrangedSubviews(
            self.completionButton,
            constraints:
            self.completionButton.widthAnchor
                .constraint(equalToConstant: width),
            self.completionButton.heightAnchor
                .constraint(equalToConstant: 48)
        )
    }

    private func setupFixedCompletionButton(rootview: UIView) {
        let safeAreaBottomHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0

        rootview.addSubviews(
            self.bottomFixedView,
            constraints:
            self.bottomFixedView.bottomAnchor
                .constraint(equalTo: rootview.bottomAnchor),
            self.bottomFixedView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.bottomFixedView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor),
            self.bottomFixedView.heightAnchor.constraint(
                equalToConstant: self.hideCompletionButton
                    ? safeAreaBottomHeight
                    : self.form.completionButtonPotition
                    .bottomFixedViewHeight + safeAreaBottomHeight
            )
        )

        self.bottomFixedView.addSubviews(
            self.completionButton,
            constraints:
            self.completionButton.topAnchor.constraint(
                equalTo: self.bottomFixedView.topAnchor,
                constant: 8
            ),
            self.completionButton.trailingAnchor.constraint(
                equalTo: self.bottomFixedView.trailingAnchor,
                constant: -8
            ),
            self.completionButton.leadingAnchor.constraint(
                equalTo: self.bottomFixedView.leadingAnchor,
                constant: 8
            ),
            self.completionButton.bottomAnchor.constraint(
                equalTo: self.bottomFixedView.bottomAnchor,
                constant: -(24 + safeAreaBottomHeight)
            )
        )
    }

    private func setupRightBarButtonItem(navigationItem: UINavigationItem) {
        let searchBarButtonItem = UIBarButtonItem(customView: completionButton)
        navigationItem.rightBarButtonItem = searchBarButtonItem
    }
}
