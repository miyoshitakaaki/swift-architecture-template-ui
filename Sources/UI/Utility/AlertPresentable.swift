import UIKit
import Utility

public protocol AlertPresentable {
    func present(_ error: AppError)
    func didAuthErrorOccured()
}

public extension AlertPresentable where Self: UIViewController {
    func present(_ error: AppError) {
        switch error {
        case .normal, .offline:
            let alert = UIAlertController(
                title: error.localizedDescription,
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        case .auth:
            let alert = UIAlertController(
                title: "ログインしてください",
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "はい", style: .default, handler: { [weak self] _ in
                self?.didAuthErrorOccured()
            }))
            self.present(alert, animated: true)
        case .invalid:
            let alert = UIAlertController(
                title: "バリデーションエラー",
                message: nil,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "はい", style: .default, handler: { [weak self] _ in
                self?.didAuthErrorOccured()
            }))
            self.present(alert, animated: true)

        case .unknown, .hms, .empty:
            break
        }
    }

    func didAuthErrorOccured() {}
}
