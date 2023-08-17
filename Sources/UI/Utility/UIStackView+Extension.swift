#if !os(macOS)
import UIKit

public extension UIStackView {
    func addArrangedSubviews(_ views: UIView..., constraints: NSLayoutConstraint...) {
        views.forEach {
            addArrangedSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        constraints.forEach { $0.isActive = true }
    }
}
#endif
