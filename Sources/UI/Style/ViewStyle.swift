import UIKit

public extension ViewStyle where T: UIView {
    static var cornerRadius: ViewStyle<T> {
        ViewStyle<T> {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        }
    }
}
