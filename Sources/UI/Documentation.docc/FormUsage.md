# Create Form and FormConfirm UI

Usage of Form and FormConfirm

## Overview

Usage of Form and FormConfirm.

### Form
1. create Form setting class conform to ``Form``.

```swift
class SampleForm: Form {
    typealias NavContent = TitleNavigationContent

    struct Input: Initializable, Equatable, Validatable {
        var title = ""
        var body = ""

        var invalidTitle = ""
    }

    var views: [UIView] {
        self.titleEdit.titleLabel
        FormSpacer(8)
        self.titleEdit.edit
        FormSpacer(8)
        self.bodyEdit.titleLabel
        FormSpacer(8)
        self.bodyEdit.edit
        FormSpacer(24)
    }

    var title: String { "サンプル" }

    var completionButtonTitle: String { "保存" }

    var data: AnyPublisher<Input, Never> {
        self.titleEdit
            .combineLatest(self.bodyEdit)
            .map { title, body in
                var data = Input()
                data.title = title
                data.body = body
                return data
            }
            .eraseToAnyPublisher()
    }

    var fetch: () async -> Result<Input, AppError> {{ [weak self] in
        guard let self else { return .success(.init()) }

        if self.isEdit {
            let result = await Domain.Usecase.Sample.Get.shared().execute(userId: 1)

            switch result {
            case let .success(entities):
                let input = entities.first
                .map { entity in
                    Input(title: entity.title, body: entity.body)
                }

                guard let input else { return .success(.init()) }

                self.titleEdit.edit.text = input.title
                self.bodyEdit.edit.text = input.body

                return .success(input)
            case let .failure(error):
                return .failure(error)
            }

        } else {
            return .success(.init())
        }

    }}

    func complete(_ input: Input) async -> Result<Input, AppError> {
        .success(input)
    }

    private let titleEdit: TextEdit<FormTextField> =
        create(edit: .standard(title: "タイトル", placeholder: ""))

    private let bodyEdit: TextEdit<FormTextField> =
        create(edit: .standard(title: "本文", placeholder: ""))

    let isEdit: Bool

    init(isEdit: Bool) {
        self.isEdit = isEdit
    }
}

```

2. use ``create(form:navContent:hideCompletionButton:)`` to create ViewController of form screen.

```swift
let form = SampleForm(isEdit: false)
let vc = create(form: form, navContent: .init())
```

### FormConfirm
1. create FormConfirm setting class conform to ``FormConfirmProtocol``.

```swift
@MainActor
class SampleConfirm: FormConfirmUIProtocol, FormConfirmProtocol {
    var data: SampleForm.Input

    var views: [UIView] {
        [
            FormSectionLabel(title: "サンプル", leftInset: 32),
            FormTitleLabel(title: "Title", leftInset: 32),
            FormConfirmLabel(title: self.data.title, leftInset: 32),
            FormTitleLabel(title: "Body", leftInset: 32),
            FormConfirmLabel(title: self.data.body, leftInset: 32),
            FormSpacer(24),
        ]
    }

    var title: String { "サンプル確認" }

    var completionButtonTitle: String { "完了" }

    init(data: SampleForm.Input) {
        self.data = data
    }

    var complete: () async -> Result<Empty, AppError> {{ [weak self] in
        guard let self else { return .success(.init()) }

        let result = await Domain.Usecase.Sample.Register.shared().execute(
            title: self.data.title,
            body: self.data.body
        )

        switch result {
        case .success:
            return .success(.init())

        case let .failure(error):
            return .failure(error)
        }
    }}
}

```

2. use ``create(formConfirm:)`` to create ViewController of form confirm screen.

```swift
let confirm = SampleConfirm(data: .init(title: "title", body: "body"))
let vc = create(formConfirm: confirm)

```

## Flow

```swift
import Navigation
import UI
import UIKit

enum SampleFlowChild {
    case form
    case formConfirm(data: SampleForm.Input)
}

final class SampleFlow: AnyFlow<BaseFlow<SampleFlowChild>> {
    override var childProvider: (SampleFlowChild) -> UIViewController {{ [weak self] child in
        guard let self else { return .init(nibName: nil, bundle: nil) }

        switch child {
        case .form:
            let vc = create(
                form: SampleForm(isEdit: false),
                navContent: TitleNavigationContent(title: "form")
            )

            vc.delegate = self

            return vc

        case let .formConfirm(data):
            let vc = create(formConfirm: SampleConfirm(data: data))
            return vc
        }
    }}
}

extension SampleFlow: FormViewControllerDelegate {
    func didCompletionButtonTapped<F>(data: F.Input, form: F) where F: UI.Form {
        switch data {
        case let data as SampleForm.Input:
            self.show(.formConfirm(data: data))
        default:
            break
        }
    }
}

```
