#if !os(macOS)
import UIKit

public protocol Stack: AnalyticsScreenName {
    func setupContent(stackView: UIStackView)
}

public extension Stack {
    func addStackView(stackView: UIStackView, view: UIView, margin: CGFloat = 0) {
        stackView.addArrangedSubviews(
            view,
            constraints:
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - margin * 2)
        )
    }
}
#endif
