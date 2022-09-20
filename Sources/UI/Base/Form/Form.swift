import Combine
import UIKit
import Utility

public protocol FormUIProtocol {
    var backgroundColor: UIColor { get }
    var completionButtonTitle: String { get }
    var completionButtonPotition: CompletionButtonPosition { get }
    var completionButtonPotitionTopStyle: ViewStyle<UIButton> { get }
    var completionButtonPotitionBottomStyle: ViewStyle<UIButton> { get }
    var bottomCompletionButtonEnableBackgroundStyle: ViewStyle<UIButton> { get }
    var bottomCompletionButtondisableBackgroundStyle: ViewStyle<UIButton> { get }
    @FormViewBuilder var views: [UIView] { get }
    var titleView: UIView? { get }
    var isValid: AnyPublisher<Bool, Never> { get }
    var showInvalidAlert: Bool { get }
    var isOptional: Bool { get }
    func set(inputAccessoryView: AMKeyboardFrameTrackerView)
    func focusNextResponder()
}

public extension FormUIProtocol {
    var isOptional: Bool { false }

    var titleView: UIView? { nil }

    var showInvalidAlert: Bool { true }

    func focusNextResponder() {
        guard
            let currentResponder = self.views.combineStackView()
                .first(where: \.isFirstResponder) else { return }

        func findNextResponder(nextTag: Int = 1) -> UIView? {
            let nextResponder = self.views.combineStackView()
                .first(where: { $0.tag == currentResponder.tag + nextTag })

            if (nextResponder as? UITextField)?.isEnabled == false {
                return findNextResponder(nextTag: nextTag + 1)
            }

            if nextResponder is FormSelectionView<FormSelectionItemView> || nextResponder == nil {
                currentResponder.endEditing(true)
                return nil
            }

            return nextResponder
        }

        findNextResponder()?.becomeFirstResponder()
    }

    func set(inputAccessoryView: AMKeyboardFrameTrackerView) {
        views
            .combineStackView()
            .filter {
                $0 is UITextField || $0 is UITextView ||
                    $0 is FormSelectionView<FormSelectionItemView>
            }
            .enumerated()
            .forEach {
                ($1 as? UITextField)?.tag = $0
                ($1 as? UITextView)?.tag = $0
                ($1 as? FormSelectionView<FormSelectionItemView>)?.tag = $0
                ($1 as? UITextField)?.inputAccessoryView = inputAccessoryView
                ($1 as? UITextView)?.inputAccessoryView = inputAccessoryView
            }
    }
}

public protocol Form: AnyObject, FormUIProtocol {
    associatedtype NavContent: NavigationContent
    associatedtype Input: Initializable, Equatable, Validatable

    var isEdit: Bool { get }
    var data: AnyPublisher<Input, Never> { get }
    var fetch: AnyPublisher<Input, AppError> { get }
    var confirmAlertTitle: String? { get }
    func complete(_ input: Input) -> AnyPublisher<Input, AppError>
}

public extension Form {
    var confirmAlertTitle: String? { nil }

    var fetch: AnyPublisher<Input, AppError> {
        Just(Input()).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    var isValid: AnyPublisher<Bool, Never> {
        data.map(\.isValid).eraseToAnyPublisher()
    }

    func complete(_ input: Input) -> AnyPublisher<Input, AppError> {
        Just(input).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }

    func stack(
        views: [UIView],
        space: CGFloat = 16,
        distribution: UIStackView.Distribution = .fillEqually
    ) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = distribution
        stackView.spacing = space
        views.forEach { view in
            stackView.addArrangedSubview(view)
        }
        return stackView
    }
}

public protocol Validatable {
    var isValid: Bool { get }
    var invalidMessage: String { get }
}

public extension Validatable {
    var isValid: Bool { self.invalidMessage.isEmpty }
    var invalidMessage: String { "" }
}

public enum CompletionButtonPosition: Equatable {
    case top, bottom(width: CGFloat), bottomFix

    var bottomFixedViewHeight: CGFloat {
        switch self {
        case .top, .bottom:
            return 0
        case .bottomFix:
            return 76
        }
    }
}

private extension Collection where Element: UIView {
    func combineStackView() -> [UIView] {
        self.reduce([UIView]()) { partialResult, view in
            if let view = view as? UIStackView {
                return partialResult + view.arrangedSubviews
            } else {
                return partialResult + [view]
            }
        }
    }
}

@resultBuilder
public struct FormViewBuilder {
    public static func buildBlock(_ components: UIView...) -> [UIView] {
        components
    }
}
