import UIKit

public extension UIView {
    func addSubviews(_ views: UIView..., constraints: NSLayoutConstraint...) {
        views.forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        constraints.forEach { $0.isActive = true }
    }

    func edgeToSelf(_ view: UIView, constant: CGFloat = 0) {
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: constant),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -constant),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -constant),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: constant),
        ])
    }

    func topLineToSelf(_ view: UIView, constant: CGFloat = 0, height: CGFloat = 1) {
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.topAnchor,
                constant: constant
            ),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -constant),
            view.heightAnchor.constraint(equalToConstant: height),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: constant),
        ])
    }

    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        if let constraints = superview?.constraints {
            for constraint in constraints where self.itemMatch(
                constraint: constraint,
                layoutAttribute: layoutAttribute
            ) {
                return constraint
            }
        }
        return nil
    }

    internal func itemMatch(
        constraint: NSLayoutConstraint,
        layoutAttribute: NSLayoutConstraint.Attribute
    ) -> Bool {
        let firstItemMatch = constraint.firstItem as? UIView == self && constraint
            .firstAttribute == layoutAttribute
        let secondItemMatch = constraint.secondItem as? UIView == self && constraint
            .secondAttribute == layoutAttribute
        return firstItemMatch || secondItemMatch
    }
}
