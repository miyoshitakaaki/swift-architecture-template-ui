# Create List UI

Usage of Table and Collection.

## Overview

UI framework include UI components like grid, list, form, and so on.
This framework have constructor of each components.
This article introduced table and collection usages.

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
