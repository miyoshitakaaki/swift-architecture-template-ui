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
2. use ``create(table:content:needRefreshNotificationNames:)`` to create ViewController of table screen.

### Form
1. create Form setting class conform to ``Form``.
2. use ``create(form:navContent:hideCompletionButton:)`` to create ViewController of form screen.

### FormConfirm
1. create FormConfirm setting class conform to ``FormConfirmProtocol``.
2. use ``create(formConfirm:)`` to create ViewController of form confirm screen.

### DiffableCollection
1. create DiffableCollection setting class conform to ``DiffableCollectionSection``.
2. use ``create(type:initialReloadType:content:screenNameForAnalytics:screenEventForAnalytics:needRefreshNotificationNames:needForceRefreshNotificationNames:needSectionRefreshNotificationNames:delegate:initialPagingInfo:bottomFixedView:)`` to create ViewController of form diffable collection screen.
