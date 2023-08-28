#if !os(macOS)
import UIKit
import Utility

/// Form confirm UI setting protocol
@MainActor
public protocol FormConfirmProtocol: AnyObject, AnalyticsScreenName {
    /// form inpu type
    associatedtype InputType
    /// form output type
    associatedtype OutputType: Equatable

    /// input data
    var data: InputType { get }
    /// navigation bar title
    var title: String { get }
    /// called when completion button is tapped
    var complete: () async -> Result<OutputType, AppError> { get }
}

@MainActor
public protocol FormConfirmUIProtocol {
    var completionButtonStyle: ViewStyle<UIButton> { get }
    var completionButtonTitle: String { get }
    var views: [UIView] { get }
}

public extension FormConfirmUIProtocol {
    var completionButtonStyle: ViewStyle<UIButton> {
        .init {
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
            $0.backgroundColor = UIColor.rgba(17, 76, 190, 1)
        }
    }
}
#endif
