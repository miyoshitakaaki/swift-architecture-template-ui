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

    public let titleLabel: UILabel
    public let edit: T

    public init(
        titleStyle: ViewStyle<UILabel>,
        inValidTitleStyle: ViewStyle<UILabel>,
        title: String,
        edit: T,
        inputType: InputType = .normal,
        isRequired: Bool = false,
        requireColor: UIColor = .red
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
    }

    public var isEnabled = true {
        didSet {
            self.titleLabel.isEnabled = self.isEnabled
            self.edit.isEnabled = self.isEnabled
        }
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        String == S.Input
    {
        self.edit
            .dropFirst()
            .handleEvents(receiveOutput: { [weak self] text in

                guard let self = self else { return }

                if self.isRequired, text.isEmpty, self.isEnabled {
                    self.titleLabel.text = self.initialTitle + "(必ず入力してください)"
                    self.titleLabel.apply(self.inValidTitleStyle)
                    return
                }

                switch self.inputType {
                case .normal:
                    break

                case .phone where text.isValid(regex: .phone) == false && self.isEnabled:
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(self.inValidTitleStyle)
                    return

                case .email where text.isValid(regex: .email) == false:
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(self.inValidTitleStyle)
                    return

                case .password where text.isValid(regex: .password) == false:
                    self.titleLabel.text = self.initialTitle + "(半角英数字8文字以上で入力してください)"
                    self.titleLabel.apply(self.inValidTitleStyle)
                    return

                case .postalCode:
                    break

                default:
                    break
                }

                self.titleLabel.text = self.initialTitle
                self.titleLabel.apply(self.titleStyle)
                self.titleLabel.setSubTextColor(text: "＊", color: self.requireColor)
            })
            .subscribe(subscriber)
    }
}
