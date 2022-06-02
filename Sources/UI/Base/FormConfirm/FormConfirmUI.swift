import Combine
import UIKit

public final class FormConfirmUI {
    private let scrollView: UIScrollView

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private let completionButton: UIButton

    lazy var completionButtonPublisher: AnyPublisher<UIButton, Never> = completionButton
        .publisher(for: .touchUpInside).eraseToAnyPublisher()

    private let form: FormConfirmUIProtocol

    public init(
        form: FormConfirmUIProtocol,
        scrollViewStyle: ViewStyle<UIScrollView>,
        completionButtonTitle: String,
        completionButtonStyle: ViewStyle<UIButton>
    ) {
        self.scrollView = .init(style: scrollViewStyle)
        self.form = form
        self.completionButton = .init(
            style: completionButtonStyle,
            title: completionButtonTitle
        )
    }
}

extension FormConfirmUI: UserInterface {
    public func setupView(rootview: UIView) {
        self.inScrollView(rootview)
        self.inStackView()
        self.form.views.forEach(addStackView)
        self.setupCompletionButton()
    }
}

private extension FormConfirmUI {
    private func inScrollView(_ rootview: UIView) {
        rootview.addSubviews(
            self.scrollView,
            constraints:
            self.scrollView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.scrollView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor)
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
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        )
    }

    private func setupCompletionButton() {
        self.verticalStackView.addArrangedSubviews(
            self.completionButton,
            constraints:
            self.completionButton.widthAnchor
                .constraint(equalToConstant: UIScreen.main.bounds.width - 64),
            self.completionButton.heightAnchor.constraint(equalToConstant: 48)
        )
    }
}
