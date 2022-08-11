import Foundation
import UIKit

public final class StackUI<T: Stack>: NSObject {
    let component: T

    private let scrollView: UIScrollView = .init()

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 24
        return stackView
    }()

    public init(component: T) {
        self.component = component
    }
}

extension StackUI: UserInterface {
    public func setupNavigationBar(
        navigationBar: UINavigationBar?,
        navigationItem: UINavigationItem?
    ) {}

    public func setupView(rootview: UIView) {
        self.setupScrollView(rootview)
        self.setupStackView()
        self.component.setupContent(stackView: self.verticalStackView)
    }

    private func setupScrollView(_ rootview: UIView) {
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

    private func setupStackView() {
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
}
