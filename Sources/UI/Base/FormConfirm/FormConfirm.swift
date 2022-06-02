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
    var completionButtonTitle: String { get }
    var views: [UIView] { get }
}
