import Combine
import UIKit
import Utility

public protocol FormUIProtocol {
    var backgroundColor: UIColor { get }
    var title: String { get }
    var completionButtonTitle: String { get }
    var completionButtonPotition: CompletionButtonPosition { get }
    var views: [UIView] { get }
    var isValid: AnyPublisher<Bool, Never> { get }
    var isOptional: Bool { get }
    func set(inputAccessoryView: AMKeyboardFrameTrackerView)
    func focusNextResponder()
}

public extension FormUIProtocol {
    var backgroundColor: UIColor { UIConfig.lightGray_100 }

    var isOptional: Bool { false }

    func focusNextResponder() {
        guard let currentResponder = self.views.first(where: \.isFirstResponder) else { return }

        func findNextResponder(nextTag: Int = 1) -> UIView? {
            let nextResponder = self.views
                .first(where: { $0.tag == currentResponder.tag + nextTag })

            if (nextResponder as? UITextField)?.isEnabled == false {
                return findNextResponder(nextTag: nextTag + 1)
            }

            if nextResponder is FormSelectionView || nextResponder == nil {
                currentResponder.endEditing(true)
                return nil
            }

            return nextResponder
        }

        findNextResponder()?.becomeFirstResponder()
    }

    func set(inputAccessoryView: AMKeyboardFrameTrackerView) {
        views
            .filter { $0 is UITextField || $0 is UITextView || $0 is FormSelectionView }
            .enumerated()
            .forEach {
                ($1 as? UITextField)?.tag = $0
                ($1 as? UITextView)?.tag = $0
                ($1 as? FormSelectionView)?.tag = $0
                ($1 as? UITextField)?.inputAccessoryView = inputAccessoryView
                ($1 as? UITextView)?.inputAccessoryView = inputAccessoryView
            }
    }
}

public protocol Form: AnyObject, FormUIProtocol {
    associatedtype Input: Initializable, Equatable, Validatable

    var data: AnyPublisher<Input, Never> { get }
    var fetch: AnyPublisher<Input, AppError> { get }
    func complete(_ input: Input) -> AnyPublisher<Input, AppError>
}

public extension Form {
    var fetch: AnyPublisher<Input, AppError> {
        Just(Input()).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    var isValid: AnyPublisher<Bool, Never> {
        data.map(\.isValid).eraseToAnyPublisher()
    }

    func complete(_ input: Input) -> AnyPublisher<Input, AppError> {
        Just(input).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }
}

public protocol Validatable {
    var isValid: Bool { get }
}

public enum CompletionButtonPosition {
    case top, bottom, bottomFix

    var bottomFixedViewHeight: CGFloat {
        switch self {
        case .top, .bottom:
            return 0
        case .bottomFix:
            return 76
        }
    }
}
