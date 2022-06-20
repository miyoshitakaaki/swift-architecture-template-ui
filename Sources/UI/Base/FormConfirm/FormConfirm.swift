import Combine
import UIKit
import Utility

public protocol FormConfirmProtocol: AnyObject {
    associatedtype InputType
    associatedtype OutputType: Equatable

    var data: InputType { get }
    var title: String { get }
    var complete: AnyPublisher<OutputType, AppError> { get }
}

public protocol FormConfirmUIProtocol {
    var completionButtonStyle: ViewStyle<UIButton> { get }
    var completionButtonTitle: String { get }
    var views: [UIView] { get }
}

extension FormConfirmUIProtocol {
    var completionButtonStyle: ViewStyle<UIButton> {
        .init {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
            $0.backgroundColor = UIConfig.accentBlue
        }
    }
}
