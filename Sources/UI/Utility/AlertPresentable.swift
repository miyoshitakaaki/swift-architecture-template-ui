import UIKit
import Utility

public protocol AlertPresentable {
    func present(_ error: AppError)
    func present(title: String, message: String, action: @escaping (UIAlertAction) -> Void)
    func didAuthOKButtonTapped()
}

public extension AlertPresentable where Self: UIViewController {
    func present(title: String, message: String, action: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .cancel, handler: action))
        self.present(alert, animated: true)
    }
    
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
                self?.didAuthOKButtonTapped()
            }))
            self.present(alert, animated: true)

        case .none:
            break
        }
    }
}
