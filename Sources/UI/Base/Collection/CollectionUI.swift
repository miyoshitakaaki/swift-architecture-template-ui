#if !os(macOS)
import Combine
import Foundation
import UIKit
import Utility

public struct SelectedCellInfo<T: CollectionList> {
    public let indexPath: IndexPath
    public let viewData: T.Cell.ViewData?
    public let cell: T.Cell?
}

public final class CollectionUI<T: CollectionList>: ListUI<T>, UICollectionViewDelegate {
    private lazy var collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout(
            sectionProvider: { [weak self] _, _ in
                let width = self?.collectionView.frame.size.width
                return self?.collection.sectionLayout(width ?? 0)
            }
        )
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
        cell?.indexPath = indexPath

        return cell

    }}

    private var supplementaryViewProvider: (UICollectionView, String, IndexPath)
        -> UICollectionReusableView?
    {
        { [weak self] collectionView, kind, indexPath in

            guard let self else { return .init() }

            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: T.Header.className,
                    for: indexPath
                ) as? T.Header

                let data = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                header?.updateHeader(data: data.header)

                return header

            } else if kind == UICollectionView.elementKindSectionFooter {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: T.Footer.className,
                    for: indexPath
                ) as? T.Footer

                let data = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                footer?.updateFooter(data: data.footer)

                return footer
            } else {
                return nil
            }
        }
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<
        T.Items.Element.Section,
        T.Cell.ViewData
    > = {
        let dataSource = UICollectionViewDiffableDataSource<
            T.Items.Element.Section,
            T.Cell.ViewData
        >(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
        dataSource.supplementaryViewProvider = self.supplementaryViewProvider
        return dataSource
    }()

    let didItemSelectedPublisher = PassthroughSubject<SelectedCellInfo<T>, Never>()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<Void, Never>()
    let refreshPublisher = PassthroughSubject<Void, Never>()
    let deletePublisher = PassthroughSubject<Int, Never>()
    let errorPublisher = PassthroughSubject<AppError, Never>()

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
            viewData: cell?.viewData,
            cell: cell
        ))
    }

    @objc private func refresh() {
        self.refreshPublisher.send()
    }

    func invalidateLayout() {
        self.collectionView.collectionViewLayout.invalidateLayout()
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

    func setupBottomAnchor(hasTabber: Bool, rootview: UIView) {
        if hasTabber {
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.bottomAnchor).isActive = true
        }
    }

    var deleteItem: (IndexPath) -> Void {{ [weak self] indexPath in
        guard let self else { return }

        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        Task {
            let result = await self.collection.delete(identifier)

            switch result {
            case .success:
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteItems([identifier])
                self.dataSource.apply(snapshot, animatingDifferences: true)
                self.collectionView.reloadData()

                self.collection.emptyView?.isHidden = !snapshot.itemIdentifiers.isEmpty
                self.collection.floatingButton?.isHidden = snapshot.itemIdentifiers.isEmpty

                self.deletePublisher.send(self.dataSource.snapshot().numberOfItems)

            case let .failure(error):
                self.errorPublisher.send(error)
            }
        }

    }}

    func reload(items: T.Items) {
        self.collection.emptyView?.isHidden = !items.isEmpty
        self.collection.floatingButton?.isHidden = items.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<
            T.Items.Element.Section,
            T.Cell.ViewData
        >()

        items.enumerated().forEach { offset, element in
            snapshot.appendSections([items[offset].section])
            snapshot.appendItems(element.items, toSection: items[offset].section)
        }

        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension CollectionUI {
    private func setupCollectionView(rootview: UIView) {
        rootview.addSubviews(
            self.collectionView,
            constraints:
            self.collectionView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.collectionView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
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
#endif
