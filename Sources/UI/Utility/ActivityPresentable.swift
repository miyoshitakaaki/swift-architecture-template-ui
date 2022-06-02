import UIKit

public protocol ActivityPresentable {
    func presentActivity()
    func dismissActivity()
}

public extension ActivityPresentable where Self: UIViewController {
    func presentActivity() {
        if let activityIndicator = findActivity() {
            activityIndicator.startAnimating()
        } else {
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor
                    .constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                activityIndicator.centerYAnchor
                    .constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            ])
        }
    }

    func dismissActivity() {
        self.findActivity()?.stopAnimating()
    }

    func findActivity() -> UIActivityIndicatorView? {
        view.subviews.compactMap { $0 as? UIActivityIndicatorView }.first
    }
}
