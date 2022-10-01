import UIKit

public protocol KeyboardPresentable: UIViewController {
    func keyboardWillHide(_ notification: Notification)
    func keyboardWillShow(_ notification: Notification, offset: CGFloat)
}

public extension KeyboardPresentable {
    func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }

        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: duration, animations: {
                self.view.frame.origin.y = 0
            })
        }
    }

    func keyboardWillShow(_ notification: Notification, offset: CGFloat = 0) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else {
            return
        }

        guard
            let rect = (
                notification
                    .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
            )?.cgRectValue
        else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: duration, animations: {
                self.view.frame.origin.y = -rect.size.height + offset
            })
        }
    }
}
