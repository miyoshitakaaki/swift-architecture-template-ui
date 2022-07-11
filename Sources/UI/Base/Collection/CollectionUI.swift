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
    {{ collectionView, indexPath, viewData in

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: T.Cell.className,
            for: indexPath
        ) as? T.Cell

        cell?.viewData = viewData

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

    let didItemSelectedPublisher = PassthroughSubject<SelectedCellInfo<T>, Never>()
    let didSupplementaryViewDequeuePublisher = PassthroughSubject<
        UICollectionReusableView?,
        Never
    >()
    let additionalLoadingIndexPathPublisher = PassthroughSubject<IndexPath, Never>()
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

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        self.additionalLoadingIndexPathPublisher.send(indexPath)
    }
}

extension CollectionUI: UserInterface {
    public func setupNavigationBar(
        navigationBar: UINavigationBar?,
        navigationItem: UINavigationItem?
    ) {}

    public func setupView(rootview: UIView) {
        rootview.backgroundColor = .white
        setupEmptyView(rootview: rootview)
        setupCollectionView(rootview: rootview)
        setupTopView(view: self.collectionView)
        setupFloatingButton(rootView: rootview)
    }

    func reload(items: OrderedDictionary<String, [T.Cell.ViewData]>) {
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
        rootview.addSubviews(
            self.collectionView,
            constraints:
            self.collectionView.topAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.topAnchor),
            self.collectionView.leadingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.leadingAnchor),
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor),
            self.collectionView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor)
        )

        self.collectionView.backgroundColor = self.collection.backgroundColor
        self.collectionView.register(T.Cell.self, forCellWithReuseIdentifier: T.Cell.className)
        self.collectionView.refreshControl = RefreshControl(moveY: -self.collection.topViewHeight)
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
}
