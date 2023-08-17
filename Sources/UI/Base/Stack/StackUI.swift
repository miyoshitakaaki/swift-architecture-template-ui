#if !os(macOS)
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
    public func setupView(rootview: UIView) {
        self.setupScrollView(rootview)
        self.setupStackView()
        self.component.setupContent(stackView: self.verticalStackView)
    }

    func setupBottomAnchor(hasTabber: Bool, rootview: UIView) {
        if hasTabber {
            self.scrollView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.scrollView.bottomAnchor
                .constraint(equalTo: rootview.bottomAnchor).isActive = true
        }
    }

    private func setupScrollView(_ rootview: UIView) {
        rootview.addSubviews(
            self.scrollView,
            constraints:
            self.scrollView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor)
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
#endif
