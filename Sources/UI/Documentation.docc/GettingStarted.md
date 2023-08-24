# Getting started with UI framework

Usage of UI components including in UI framework

## Overview

UI framework include UI components like grid, list, form, and so on.
This framework have constructor of each components.
This article introduced these usages.

## Components

### Collection

1. create CollectionList setting class conform to ``CollectionList``.


```swift
@MainActor
class SampleCollection: CollectionList {
    struct NavContent: NavigationContent {
        var title: String? = "Sample"
    }

    typealias Cell = SampleListCollectionViewCell
    typealias Header = CollectionHeader
    typealias Footer = CollectionFooter
    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    var sectionLayout: (CGFloat) -> NSCollectionLayoutSection {{ _ in
        .create(
            isVertical: true,
            itemWidth: UIScreen.main.bounds.width - 32,
            itemHeight: .absolute(72)
        )
    }}

    var fetch: ((parameter: String?, isAdditional: Bool)) async -> Result<Items, AppError> {{ [weak self] _ in
        guard let self else { return .success([]) }

        let result = await Domain.Usecase.Sample.Get.shared().execute(userId: 1)

        switch result {
        case let .success(entities):
            return .success(self.mapper(entities: [entities]))

        case let .failure(error):
            return .failure(error)
        }
    }}

    func mapper(entities: [[SampleEntity]]) -> Items {
        guard entities.first?.isEmpty == false else { return [] }

        let items: [Cell.ViewData] = entities.first?.map { entity in
            .init(text: entity.title, imageUrl: entity.url)
        } ?? []

        return [
            .init(
                section: .init(
                    header: .init(),
                    footer: .init()
                ),
                items: items
            ),
        ]
    }
}

```

2. use ``create(collection:content:needRefreshNotificationNames:)`` to create ViewController of collection screen.

```swift
let collection = SampleCollection()
let vc = create(collection: collection, content: .init())
```

### Table
1. create Table setting class conform to ``Table``.

```swift
final class SampleTable: Table {
    typealias NavContent = TitleNavigationContent
    typealias Cell = SampleTableViewCell
    typealias Header = TableEmptyHeader
    typealias Footer = TableEmptyHeader

    var fetch: ((parameter: String?, isAdditional: Bool)) async -> Result<Items, AppError> {{ [weak self] _ in
        guard let self else { return .success([]) }

        let result = await Domain.Usecase.Sample.Get.shared().execute(userId: 1)

        switch result {
            case let .success(entities):
                return .success(self.mapper(entities: [entities]))

            case let .failure(error):
                return .failure(error)
        }
    }}

    func mapper(entities: [[SampleEntity]]) -> Items {
        guard entities.first?.isEmpty == false else { return [] }

        let items: [Cell.ViewData] = entities.first?.map { entity in
            .init(text: entity.title)
        } ?? []

        return [
            .init(
                section: .init(
                    header: .init(),
                    footer: .init()
                ),
                items: items
            ),
        ]
    }
}

```


2. use ``create(table:content:needRefreshNotificationNames:)`` to create ViewController of table screen.

```swift
let table = SampleTable()
let vc = create(table: table, content: .init(title: "サンプル"))

```

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
        if self.isEdit {
            let result = await Domain.Usecase.Sample.Update.shared().execute(
                title: input.title,
                body: input.body
            )

            switch result {
                case .success:
                return .success(.init())

                case let .failure(error):
                return .failure(error)
            }
        } else {
            let result = await Domain.Usecase.Sample.Register.shared().execute(
                title: input.title,
                body: input.body
            )

            switch result {
                case .success:
                return .success(.init())

                case let .failure(error):
                return .failure(error)
            }
        }
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
