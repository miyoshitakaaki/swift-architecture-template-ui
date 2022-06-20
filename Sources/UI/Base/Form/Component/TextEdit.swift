import Combine
import UIKit

public extension ViewStyle where T: UILabel {
    static var dangerRedBoldSmallSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIConfig.dangerRed
            $0.font = UIFont.boldSystemFont(ofSize: 12)
        }
    }
}

public final class TextEdit<T: UIControl>: Publisher where T: Publisher, T.Output == String,
    T.Failure == Never
{
    public typealias Output = String
    public typealias Failure = Never

    private let titleColor: UIColor
    private let initialTitle: String
    private let allowEmpty: Bool
    private let isPhone: Bool
    private let isEmail: Bool
    private let isPassword: Bool

    public let titleLabel: FormTitleLabel
    public let edit: T

    public init(
        titleColor: UIColor = UIColor.rgba(97, 97, 97, 1),
        title: String,
        edit: T,
        allowEmpty: Bool = true,
        isPhone: Bool = false,
        isEmail: Bool = false,
        isPassword: Bool = false
    ) {
        self.initialTitle = title
        self.allowEmpty = allowEmpty
        self.isPhone = isPhone
        self.isEmail = isEmail
        self.isPassword = isPassword
        self.titleLabel = .init(title: title, titleColor: titleColor)
        self.titleColor = titleColor
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

                if self.allowEmpty == false, text.isEmpty, self.isEnabled {
                    self.titleLabel.text = self.initialTitle + "(必ず入力してください)"
                    self.titleLabel.apply(.dangerRedBoldSmallSize)
                    return
                }

                if self.isPhone, text.isValid(regex: .phone) == false, self.isEnabled {
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(.dangerRedBoldSmallSize)
                    return
                }

                if self.isEmail, text.isValid(regex: .email) == false {
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(.dangerRedBoldSmallSize)
                    return
                }

                if self.isPassword, text.isValid(regex: .password) == false {
                    self.titleLabel.text = self.initialTitle + "(半角英数字8文字以上で入力してください)"
                    self.titleLabel.apply(.dangerRedBoldSmallSize)
                    return
                }

                self.titleLabel.text = self.initialTitle
                self.titleLabel.textColor = self.titleColor
                self.titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
            })
            .subscribe(subscriber)
    }
}
