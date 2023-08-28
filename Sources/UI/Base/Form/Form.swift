#if !os(macOS)
import Combine
import UIKit
import Utility

@MainActor
public protocol FormUIProtocol {
    /// screen background color
    var backgroundColor: UIColor { get }
    /// completion button title when form is optional
    var optionalButtonTitle: String { get }
    /// completion button title
    var completionButtonTitle: String { get }
    /// completion button position
    var completionButtonPotition: CompletionButtonPosition { get }
    /// completion button style when position is top
    var completionButtonPotitionTopStyle: ViewStyle<UIButton> { get }
    /// completion button style when position is bottom
    var completionButtonPotitionBottomStyle: ViewStyle<UIButton> { get }
    /// completion button enable style when position is bottom
    var bottomCompletionButtonEnableBackgroundStyle: ViewStyle<UIButton> { get }
    /// completion button disable style when position is bottom
    var bottomCompletionButtondisableBackgroundStyle: ViewStyle<UIButton> { get }
    /// form ui components
    @FormViewBuilder var views: [UIView] { get }
    /// navigation bar title view
    var titleView: UIView? { get }
    /// input data is valid or not
    var isValid: AnyPublisher<Bool, Never> { get }
    /// show or not show alert when input data is invalid
    var showInvalidAlert: Bool { get }
    /// form is optional or not
    var isOptional: Bool { get }
    /// show accesoryview on keyboard or not
    var showAccessoryView: Bool { get }
    /// accessoryView setter
    func set(inputAccessoryView: AMKeyboardFrameTrackerView)
    /// chaange responder
    func focusNextResponder()
}

public extension FormUIProtocol {
    var isOptional: Bool { false }

    var titleView: UIView? { nil }

    var showInvalidAlert: Bool { true }

    var optionalButtonTitle: String { completionButtonTitle }

    var showAccessoryView: Bool { true }

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

/// Form  UI setting protocol
@MainActor
public protocol Form: AnyObject, FormUIProtocol, AnalyticsScreenName {
    /// navigation content setting
    associatedtype NavContent: NavigationContent
    /// form data type
    associatedtype Input: Initializable, Equatable, Validatable

    /// show initial data or not
    var isEdit: Bool { get }
    /// data binding between data model and ui
    var data: AnyPublisher<Input, Never> { get }
    /// fetch content data
    var fetch: () async -> Result<Input, AppError> { get }
    /// alert title when completion button is tapped
    var confirmAlertTitle: String? { get }
    /// called when completion button tapped
    func complete(_ input: Input) async -> Result<Input, AppError>
}

public extension Form {
    var confirmAlertTitle: String? { nil }

    var fetch: () async -> Result<Input, AppError> {{ .success(Input()) }}

    var isValid: AnyPublisher<Bool, Never> {
        data.map(\.isValid).eraseToAnyPublisher()
    }

    func complete(_ input: Input) async -> Result<Input, AppError> { .success(input) }

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
    var invalidTitle: String { get }
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
#endif
