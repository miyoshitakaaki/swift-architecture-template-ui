import Combine
import UIKit

public final class TextEdit<T: UIControl>: Publisher where T: Publisher, T.Output == String,
    T.Failure == Never
{
    public typealias Output = String
    public typealias Failure = Never

    private let titleStyle: ViewStyle<UILabel>
    private let initialTitle: String
    private let allowEmpty: Bool
    private let isPhone: Bool
    private let isEmail: Bool
    private let isPassword: Bool

    public let titleLabel: UILabel
    public let edit: T

    public init(
        titleStyle: ViewStyle<UILabel>,
        title: String,
        edit: T,
        allowEmpty: Bool = true,
        isPhone: Bool = false,
        isEmail: Bool = false,
        isPassword: Bool = false,
        isRequired: Bool = false,
        requireColor: UIColor = .red
    ) {
        self.initialTitle = title
        self.allowEmpty = allowEmpty
        self.isPhone = isPhone
        self.isEmail = isEmail
        self.isPassword = isPassword
        self.titleLabel = .init(
            style: titleStyle,
            title: isRequired ? title + "＊" : title
        )
        self.titleLabel.setSubTextColor(text: "＊", color: requireColor)
        self.edit = edit
        self.titleStyle = titleStyle
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
                    self.titleLabel.apply(.init {
                        $0.textColor = UIConfig.dangerRed
                        $0.font = UIFont.boldSystemFont(ofSize: 12)
                    })
                    return
                }

                if self.isPhone, text.isValid(regex: .phone) == false, self.isEnabled {
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(.init {
                        $0.textColor = UIConfig.dangerRed
                        $0.font = UIFont.boldSystemFont(ofSize: 12)
                    })
                    return
                }

                if self.isEmail, text.isValid(regex: .email) == false {
                    self.titleLabel.text = self.initialTitle + "(正しい書式で入力してください)"
                    self.titleLabel.apply(.init {
                        $0.textColor = UIConfig.dangerRed
                        $0.font = UIFont.boldSystemFont(ofSize: 12)
                    })
                    return
                }

                if self.isPassword, text.isValid(regex: .password) == false {
                    self.titleLabel.text = self.initialTitle + "(半角英数字8文字以上で入力してください)"
                    self.titleLabel.apply(.init {
                        $0.textColor = UIConfig.dangerRed
                        $0.font = UIFont.boldSystemFont(ofSize: 12)
                    })
                    return
                }

                self.titleLabel.text = self.initialTitle
                self.titleLabel.apply(self.titleStyle)
            })
            .subscribe(subscriber)
    }
}
