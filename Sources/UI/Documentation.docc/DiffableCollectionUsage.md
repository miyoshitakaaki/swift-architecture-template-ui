# Create multi cell collection UI

usage of DiffableCollection

## Overview

DiffableCollection support multi cell.

## Definition

```swift
import Combine
import Foundation
import UI
import UIKit
import Utility

@MainActor
enum SampleDifferableCollection: DiffableCollectionSection {
    case sample, other

    private(set) static var sections: [SampleDifferableCollection] = []

    static func reload(
        fetchRemote: Bool
    ) async -> Result<[SampleDifferableCollection], AppError> {
        var items: [Self] = []

        items.append(.sample)
        items.append(.other)
        Self.sections = items

        return .success(items)
    }

    var headerText: String {
        switch self {
        case .sample:
            return "sampleHeader"
        case .other:
            return "otherHeader"
        }
    }

    var headerSecondaryText: String {
        switch self {
        case .sample:
            return "sampleSecondaryText"
        case .other:
            return "otherSecondaryText"
        }
    }

    func supplementaryRegistration(
        collectionView: UICollectionView,
        kind: String,
        supplementaryRegistration: SampleSupplementaryRegistration,
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        collectionView.dequeueConfiguredReusableSupplementary(
            using: supplementaryRegistration.header,
            for: indexPath
        )
    }

    func fetch(fetchRemote: Bool) async -> Result<[SampleItem], Utility.AppError> {
        switch self {
            case .sample:
                return .success([
                .sample(.init()),
                .sample(.init()),
                .sample(.init()),
                ])

            case .other:
                return .success([
                .other(.init()),
                .other(.init()),
                .other(.init()),
                ])
        }
    }

    func layout(
        section: Int,
        environment: NSCollectionLayoutEnvironment,
        items: [SampleItem],
        pagingInfoSubject: PassthroughSubject<UI.PagingSectionFooterView.PagingInfo, Never>
    ) -> NSCollectionLayoutSection {
        switch self {
            case .sample:
            return .create(
                isVertical: true,
                itemWidth: UIScreen.main.bounds.width - 32,
                itemHeight: .absolute(72),
                headerHeight: .absolute(44)
            )

            case .other:
            return .create(
                isVertical: true,
                itemWidth: UIScreen.main.bounds.width - 32,
                itemHeight: .absolute(72),
                headerHeight: .absolute(44)
            )
        }
    }

    func cellRegistration(
        cellRegistration: SampleCellRegistration,
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: SampleItem
    ) -> UICollectionViewCell? {
        switch item {
        case let .sample(data):
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration.sample,
                for: indexPath,
                item: data
            )

        case let .other(data):
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration.other,
                for: indexPath,
                item: data
            )
        }
    }
}

```

```swift
import UIKit
import Utility

@MainActor
struct SampleCellRegistration: Initializable {
    let sample = UICollectionView
        .CellRegistration<
        SampleDifferableCollectionViewCell,
        SampleDifferableCollectionViewCell.ViewData
    >() { cell, _, itemIdentifier in
        cell.viewData = itemIdentifier
    }

    let other = UICollectionView
        .CellRegistration<
        SampleOtherDifferableCollectionViewCell,
        SampleOtherDifferableCollectionViewCell.ViewData
    >() { cell, _, itemIdentifier in
        cell.viewData = itemIdentifier
    }

    nonisolated init() {}
}
```

```swift
import Combine
import UI
import UIKit

@MainActor
class SampleSupplementaryRegistration: PagingInfoInitializable {
    let header: UICollectionView.SupplementaryRegistration<SampleCollectionHeader> = .init(
        elementKind: UICollectionView.elementKindSectionHeader
    ) { @MainActor supplementaryView, _, indexPath in
        let section = SampleDifferableCollection.sections[indexPath.section]
        supplementaryView.viewData = .init(
            title: section.headerText,
            subTitle: section.headerSecondaryText
        )
    }

    let footerPaging: UICollectionView.SupplementaryRegistration<PagingSectionFooterView>

    required init(
        initialPagingInfo: [PagingSectionFooterView.InitialPagingInfo],
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>,
        pagingControlSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    ) {
        self.footerPaging = .init(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { @MainActor supplementaryView, _, indexPath in
            let info = initialPagingInfo.first(where: { $0.section == 0 })
            supplementaryView.configure(initialPagingInfo: info!)
            supplementaryView.subscribeTo(
                subject: pagingInfoSubject,
                pageControlsubject: pagingControlSubject,
                for: indexPath.section
            )
        }
    }
}

```

```swift
enum SampleItem: Hashable, Sendable {
    case sample(SampleDifferableCollectionViewCell.ViewData)
    case other(SampleOtherDifferableCollectionViewCell.ViewData)
}
```

## Usage

- ``create(type:initialReloadType:content:screenNameForAnalytics:screenEventForAnalytics:needRefreshNotificationNames:needForceRefreshNotificationNames:needSectionRefreshNotificationNames:initialPagingInfo:bottomFixedView:)``


```swift
let vc = create(
    type: SampleDifferableCollection.self,
    initialReloadType: .remote(),
    content: TitleNavigationContent()
)

```
