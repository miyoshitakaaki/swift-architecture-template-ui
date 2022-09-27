import UIKit
import Utility

public protocol AlertPresentable {
    func present(_ error: AppError)
    func didOKButtonTapped()
}

public extension AlertPresentable where Self: UIViewController {
    func present(_ error: AppError) {
        switch error {
        case let .normal(title, message):
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .cancel))
            self.present(alert, animated: true)

        case let .auth(title, message):
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default, handler: { [weak self] _ in
                self?.didOKButtonTapped()
            }))
            self.present(alert, animated: true)

        case .none:
            break
        }
    }

    func didOKButtonTapped() {}
}
