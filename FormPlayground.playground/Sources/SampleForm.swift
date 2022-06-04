import Combine
import Foundation
import UI
import UIKit

public class SampleForm: Form {
    public struct InputType: Equatable, Initializable, Validatable {
        public var old = ""
        public var new = ""
        public var passwordConfirm = ""

        public init() {}

        public var isValid: Bool {
            !self.old.isEmpty &&
                !self.new.isEmpty &&
                !self.passwordConfirm.isEmpty &&
                self.new == self.passwordConfirm &&
                self.old.isValid(regex: .password) &&
                self.new.isValid(regex: .password) &&
                self.passwordConfirm.isValid(regex: .password)
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
    public var views: [UIView] {
        [
            self.oldPasswordEdit.titleLabel,
            self.oldPasswordEdit.edit,
            self.newPasswordEdit.titleLabel,
            self.newPasswordEdit.edit,
            self.newPasswordConfirmViewEdit.titleLabel,
            self.newPasswordConfirmViewEdit.edit,
        ]
    }

    public var data: AnyPublisher<InputType, Never> {
        Publishers.CombineLatest3(
            self.oldPasswordEdit,
            self.newPasswordEdit,
            self.newPasswordConfirmViewEdit
        )
        .map { data1, data2, data3 in
            var data = Input()
            data.old = data1
            data.new = data2
            data.passwordConfirm = data3
            return data
        }
        .eraseToAnyPublisher()
    }

    public init() {}
}
