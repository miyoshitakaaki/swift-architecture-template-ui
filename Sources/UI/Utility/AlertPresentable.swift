import UIKit
import Utility

public protocol AlertPresentable: UIViewController {}

public extension AlertPresentable {
    func present(
        title: String,
        message: String,
        messageAlignment: NSTextAlignment? = nil,
        okButtonTitle: String = "OK",
        action: @escaping (UIAlertAction) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        if let messageAlignment {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = messageAlignment
            let messageText = NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                ]
            )

            alert.setValue(messageText, forKey: "attributedMessage")
        }

        alert.addAction(
            .init(
                title: okButtonTitle,
                style: .default,
                handler: action
            )
        )
        self.present(alert, animated: true)
    }

    func present(
        title: String,
        message: String,
        messageAlignment: NSTextAlignment? = nil,
        okButtonTitle: String = "OK",
        cancelButtonTitle: String = "キャンセル",
        okAction: @escaping (UIAlertAction) -> Void,
        cancelAction: @escaping (UIAlertAction) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        if let messageAlignment {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = messageAlignment
            let messageText = NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                ]
            )

            alert.setValue(messageText, forKey: "attributedMessage")
        }

        alert.addAction(
            .init(
                title: cancelButtonTitle,
                style: .cancel,
                handler: cancelAction
            )
        )
        alert.addAction(
            .init(
                title: okButtonTitle,
                style: .default,
                handler: okAction
            )
        )
        self.present(alert, animated: true)
    }
}
