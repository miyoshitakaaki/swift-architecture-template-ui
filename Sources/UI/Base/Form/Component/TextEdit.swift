import Combine
import UIKit

public final class TextEdit<T: UIControl>: Publisher where T: Publisher, T.Output == String,
    T.Failure == Never
{
    public enum InputType {
        case normal, phone, email, password, postalCode
    }

    public typealias Output = String
    public typealias Failure = Never

    private let titleStyle: ViewStyle<UILabel>
    private let inValidTitleStyle: ViewStyle<UILabel>
    private let initialTitle: String
    private let inputType: InputType
    private let isRequired: Bool
    private let requireColor: UIColor
    private let showValidationError: Bool

    public let titleLabel: UILabel
    public let edit: T

    public init(
        titleStyle: ViewStyle<UILabel>,
        inValidTitleStyle: ViewStyle<UILabel>,
        title: String,
        edit: T,
        inputType: InputType = .normal,
        isRequired: Bool = false,
        requireColor: UIColor = .red,
        showValidationError: Bool = false
    ) {
        self.titleStyle = titleStyle
        self.inValidTitleStyle = inValidTitleStyle
        self.initialTitle = isRequired ? title + "＊" : title
        self.inputType = inputType
        self.isRequired = isRequired
        self.requireColor = requireColor

        self.titleLabel = .init(
            style: titleStyle,
            title: self.initialTitle
        )
        self.titleLabel.setSubTextColor(text: "＊", color: requireColor)
        self.edit = edit
        self.showValidationError = showValidationError
    }

    public var isEnabled = true {
        didSet {
            self.edit.isEnabled = self.isEnabled
        }
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        String == S.Input
    {
        self.edit
            .handleEvents(receiveOutput: { [weak self] text in

                guard let self else { return }

                guard self.showValidationError else { return }

                if self.isRequired, text.isEmpty, self.isEnabled {
                    self.titleLabel.text = self.initialTitle + "(必ず入力してください)"
                    self.titleLabel.apply(self.inValidTitleStyle)
                    return
                }

                self.titleLabel.text = self.initialTitle
                self.titleLabel.apply(self.titleStyle)
                self.titleLabel.setSubTextColor(text: "＊", color: self.requireColor)
            })
            .subscribe(subscriber)
    }
}
