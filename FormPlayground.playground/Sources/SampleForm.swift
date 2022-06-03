import Combine
import Foundation
import UI
import UIKit

public class SampleForm: Form {
    public struct InputType: Equatable, Initializable, Validatable {
        let text = ""

        public init() {}

        public var isValid: Bool { !self.text.isEmpty }
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
        Just(.init()).eraseToAnyPublisher()
    }

    public init() {}
}
