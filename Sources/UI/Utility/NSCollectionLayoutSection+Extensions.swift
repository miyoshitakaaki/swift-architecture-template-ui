import Combine
import UIKit

@MainActor
public extension NSCollectionLayoutSection {
    static func create(
        isVertical: Bool,
        rowCount: Int = 1,
        itemWidth: CGFloat,
        itemHeight: NSCollectionLayoutDimension,
        interGroupSpacing: CGFloat = 16,
        headerHeight: CGFloat,
        footerHeight: CGFloat = 56,
        leading: CGFloat = 16,
        trailing: CGFloat = 16,
        bottom: CGFloat = 48,
        orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior,
        showHeader: Bool,
        pinToVisibleBounds: Bool = false,
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>? = nil,
        showFooter: Bool
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: itemHeight
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth * CGFloat(rowCount) + 16 * CGFloat(rowCount - 1)),
            heightDimension: itemHeight
        )

        let group = {
            if isVertical {
                if rowCount > 1 {
                    return NSCollectionLayoutGroup.vertical(
                        layoutSize: groupSize,
                        subitem: item,
                        count: rowCount
                    )
                } else {
                    return NSCollectionLayoutGroup.vertical(
                        layoutSize: groupSize,
                        subitems: [item]
                    )
                }
            } else {
                if rowCount > 1 {
                    return NSCollectionLayoutGroup.horizontal(
                        layoutSize: groupSize,
                        subitem: item,
                        count: rowCount
                    )
                } else {
                    return NSCollectionLayoutGroup.horizontal(
                        layoutSize: groupSize,
                        subitems: [item]
                    )
                }
            }
        }()

        if rowCount > 1 {
            group.interItemSpacing = .fixed(16)
        }

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interGroupSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
        section.orthogonalScrollingBehavior = orthogonalScrollingBehavior

        if showHeader {
            let sectionHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(headerHeight)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            sectionHeaderItem.pinToVisibleBounds = pinToVisibleBounds
            section.boundarySupplementaryItems += [sectionHeaderItem]
        }

        if showFooter {
            let sectionFooterItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(footerHeight)
                ),
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )

            section.boundarySupplementaryItems += [sectionFooterItem]
        }

        if let pagingInfoSubject {
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(20)
            )

            let pagingFooterElement = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )

            pagingFooterElement.contentInsets.top = -(bottom + 16)

            section.boundarySupplementaryItems += [pagingFooterElement]

            section.visibleItemsInvalidationHandler = { _, offset, _ in
                let page = round(offset.x / (itemWidth + interGroupSpacing))

                pagingInfoSubject.send(
                    PagingSectionFooterView.PagingInfo(
                        sectionIndex: 0,
                        currentPage: Int(page),
                        isFirstIndex: false,
                        offset: leading
                    )
                )
            }
        }

        return section
    }
}
