import Combine
import Foundation
import UI
import UIKit

public class SampleForm: Form {
    public struct InputType: Equatable, Initializable, Validatable {
        public var old = ""
        public var new = ""
        public var passwordConfirm = ""
        public var birthday = ""
        public var gender = ""
        public var email = ""
        public var phone = ""

        public init() {}

        public var isValid: Bool {
            !self.old.isEmpty &&
                !self.new.isEmpty &&
                !self.passwordConfirm.isEmpty &&
                self.new == self.passwordConfirm &&
                self.old.isValid(regex: .password) &&
                self.new.isValid(regex: .password) &&
                self.passwordConfirm.isValid(regex: .password) &&
                !self.birthday.isEmpty &&
                !self.gender.isEmpty &&
                !self.email.isEmpty &&
                self.email.isValid(regex: .email) &&
                !self.phone.isEmpty &&
                self.phone.isValid(regex: .phone)
        }
    }

    public typealias Input = InputType

    public var title: String { "SampleForm" }

    public var completionButtonTitle: String { "完了" }

    public var completionButtonPotition: CompletionButtonPosition { .bottomFix }

    private let oldPasswordEdit: TextEdit<FormTextField> = .init(
        title: "現在のパスワード",
        edit: .init(
            placeholder: "",
            textContentType: .password,
            showOptionButton: true,
            isSecureTextEntry: true
        ),
        allowEmpty: false,
        isPassword: true
    )

    private let newPasswordEdit: TextEdit<FormTextField> = .init(
        title: "新しいパスワード",
        edit: .init(
            placeholder: "",
            textContentType: .password,
            showOptionButton: true,
            isSecureTextEntry: true
        ),
        allowEmpty: false,
        isPassword: true
    )

    private let newPasswordConfirmViewEdit: TextEdit<FormTextField> = .init(
        title: "新しいパスワード（再確認）",
        edit: .init(
            placeholder: "",
            textContentType: .password,
            showOptionButton: true,
            isSecureTextEntry: true
        ),
        allowEmpty: false,
        isPassword: true
    )

    private let birthdayEdit: TextEdit<FormTextField> = .init(
        title: "生年月日",
        edit: .init(placeholder: "", picker: .date(.birthday)),
        allowEmpty: false
    )

    private let genderEdit: TextEdit<FormTextField> = .init(
        title: "性別",
        edit: .init(placeholder: "", picker: .list(["", "男性", "女性"])),
        allowEmpty: false
    )

    private let emailEdit: TextEdit<FormTextField> = .init(
        title: "メールアドレス",
        edit: .init(placeholder: "", textContentType: .emailAddress),
        allowEmpty: false,
        isEmail: true
    )

    private let phoneEdit: TextEdit<FormTextField> = .init(
        title: "電話番号",
        edit: .init(placeholder: "例：08012345678", textContentType: .telephoneNumber),
        allowEmpty: false,
        isPhone: true
    )

    public var views: [UIView] {
        [
            self.oldPasswordEdit.titleLabel,
            self.oldPasswordEdit.edit,
            self.newPasswordEdit.titleLabel,
            self.newPasswordEdit.edit,
            self.newPasswordConfirmViewEdit.titleLabel,
            self.newPasswordConfirmViewEdit.edit,
            self.birthdayEdit.titleLabel,
            self.birthdayEdit.edit,
            self.genderEdit.titleLabel,
            self.genderEdit.edit,
            self.emailEdit.titleLabel,
            self.emailEdit.edit,
            self.phoneEdit.titleLabel,
            self.phoneEdit.edit,
        ]
    }

    public var data: AnyPublisher<InputType, Never> {
        self.oldPasswordEdit
            .combineLatest(self.newPasswordEdit)
            .combineLatest(self.newPasswordConfirmViewEdit)
            .combineLatest(self.birthdayEdit)
            .combineLatest(self.genderEdit)
            .combineLatest(self.emailEdit)
            .combineLatest(self.phoneEdit)
            .map { data in
                let (
                    (((((oldPassword, newPassword), newPasswordConfirm), birthday), gender), email),
                    phone
                ) = data
                var data = Input()
                data.old = oldPassword
                data.new = newPassword
                data.passwordConfirm = newPasswordConfirm
                data.birthday = birthday
                data.gender = gender
                data.email = email
                data.phone = phone
                return data
            }
            .eraseToAnyPublisher()
    }

    public init() {}
}
