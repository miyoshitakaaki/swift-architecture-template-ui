import Combine
import Foundation
import OrderedCollections
import UIKit
import Utility

public struct SelectedCellInfo<T: CollectionList> {
    public let indexPath: IndexPath
    public let viewData: T.Cell.ViewData?
}

public final class CollectionUI<T: CollectionList>: ListUI<T>, UICollectionViewDelegate {
    private lazy var collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: collection.composableLayout
    )

    private var cellProvider: (UICollectionView, IndexPath, T.Cell.ViewData)
        -> UICollectionViewCell?
    {{ [weak self] collectionView, indexPath, viewData in

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: T.Cell.className,
            for: indexPath
        ) as? T.Cell

        cell?.viewData = viewData
        cell?.delete = self?.deleteItem

        self?.didCellDequeuePublisher.send((cell, indexPath))

        return cell

    }}

    private var supplementaryViewProvider: (UICollectionView, String, IndexPath)
        -> UICollectionReusableView?
    {
        { [weak self] collectionView, kind, indexPath in

            guard let self = self else { return .init() }

            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: T.Header.className,
                    for: indexPath
                ) as? T.Header

                let text = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                header?.updateHeader(text: text)

                self.didSupplementaryViewDequeuePublisher.send(header)

                return header

            } else if kind == UICollectionView.elementKindSectionFooter {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: T.Footer.className,
                    for: indexPath
                ) as? T.Footer

                self.didSupplementaryViewDequeuePublisher.send(footer)

                return footer
            } else {
                return nil
            }
        }
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<String, T.Cell.ViewData> = {
        let dataSource = UICollectionViewDiffableDataSource<String, T.Cell.ViewData>(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
        dataSource.supplementaryViewProvider = supplementaryViewProvider
        return dataSource
    }()

    let didCellDequeuePublisher = PassthroughSubject<(T.Cell?, IndexPath), Never>()
    let didItemSelectedPublisher = PassthroughSubject<SelectedCellInfo<T>, Never>()
    let didSupplementaryViewDequeuePublisher = PassthroughSubject<
        UICollectionReusableView?,
        Never
    >()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<Void, Never>()
    let refreshPublisher = PassthroughSubject<Void, Never>()

    private let collection: T

    public init(collection: T) {
        self.collection = collection
        super.init(list: collection)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let cell = self.collectionView.cellForItem(at: indexPath) as? T.Cell
        self.didItemSelectedPublisher.send(SelectedCellInfo(
            indexPath: indexPath,
            viewData: cell?.viewData
        ))
    }

    @objc private func refresh() {
        self.refreshPublisher.send()
    }

    func endRefresh() {
        self.collectionView.refreshControl?.endRefreshing()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.collectionView else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.frame.height
        let contentInset = scrollView.contentInset
        let viewedHeight = offsetY + viewHeight - contentInset.bottom
        if viewedHeight > contentHeight {
            self.additionalLoadingIndexPathPublisher.send(())
        }
    }
}

extension CollectionUI: UserInterface {
    public func setupView(rootview: UIView) {
        rootview.backgroundColor = .white
        setupCollectionView(rootview: rootview)
        setupTopView(view: self.collectionView)
        setupFloatingButton(rootView: rootview)
        setupEmptyView()
    }

    var deleteItem: (IndexPath) -> Void {{ [weak self] indexPath in
        guard let self = self else { return }

        var snapshot = self.dataSource.snapshot()
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
        snapshot.deleteItems([identifier])
        self.dataSource.apply(snapshot, animatingDifferences: false)
        self.collectionView.reloadData()

        self.collection.emptyView?.isHidden = !snapshot.itemIdentifiers.isEmpty
        self.collection.floatingButton?.isHidden = snapshot.itemIdentifiers.isEmpty

    }}

    func reload(items: OrderedDictionary<String, [T.Cell.ViewData]>) {
        self.collection.emptyView?.isHidden = !items.elements.isEmpty
        self.collection.floatingButton?.isHidden = items.elements.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<String, T.Cell.ViewData>()

        items.enumerated().forEach { offset, element in
            snapshot.appendSections([items.keys[offset]])
            snapshot.appendItems(element.value, toSection: items.keys[offset])
        }

        self.dataSource.apply(snapshot, animatingDifferences: false)

        self.collectionView.reloadData()
    }
}

private extension CollectionUI {
    private func setupCollectionView(rootview: UIView) {
        let bottom = self.collection.hideTabbar
            ? rootview.bottomAnchor
            : rootview.safeAreaLayoutGuide.bottomAnchor

        rootview.addSubviews(
            self.collectionView,
            constraints:
            self.collectionView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.collectionView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.collectionView.bottomAnchor
                .constraint(equalTo: bottom),
            self.collectionView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor)
        )

        self.collectionView.backgroundColor = self.collection.backgroundColor
        self.collectionView.register(T.Cell.self, forCellWithReuseIdentifier: T.Cell.className)

        if self.collection.pullToRefreshable {
            self.collectionView
                .refreshControl = RefreshControl(moveY: -self.collection.topViewHeight)
        }
        self.collectionView.refreshControl?.addTarget(
            self,
            action: #selector(self.refresh),
            for: .valueChanged
        )

        self.collectionView.contentInset.bottom = 16

        self.collectionView.register(
            T.Header.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: T.Header.className
        )

        self.collectionView.register(
            T.Footer.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: T.Footer.className
        )
        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
    }

    private func setupFloatingButton(rootView: UIView) {
        guard let button = self.collection.floatingButton else { return }
        button.isHidden = true
        rootView.addSubviews(
            button,
            constraints:
            button.bottomAnchor.constraint(
                equalTo: rootView.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            ),
            button.leadingAnchor.constraint(
                equalTo: rootView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            button.trailingAnchor.constraint(
                equalTo: rootView.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            button.heightAnchor.constraint(equalToConstant: 56)
        )
    }

    private func setupEmptyView() {
        self.collectionView.backgroundView = self.collection.emptyView
        self.collection.emptyView?.isHidden = true
    }
}
