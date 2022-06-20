import UIKit

extension ViewStyle where T: UITextView {
    static var cornerRadius: ViewStyle<T> {
        ViewStyle<T> {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        }
    }
}
