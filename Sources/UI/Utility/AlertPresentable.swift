import UIKit
import Utility

public protocol AlertPresentable {
    func present(
        title: String,
        message: String,
        action: @escaping (UIAlertAction) -> Void
    )
}

public extension AlertPresentable where Self: UIViewController {
    func present(
        title: String,
        message: String,
        action: @escaping (UIAlertAction) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            .init(
                title: "OK",
                style: .cancel,
                handler: action
            )
        )
        self.present(alert, animated: true)
    }
}
