import Combine
import Foundation
import UIKit

public final class DiffableCollectionUI<
    S: DiffableCollectionSection
>: NSObject,
    UICollectionViewDelegate
{
    private lazy var collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: composableLayout
    )

    private let cellRegistration: S.CellRegistration
    private let supplementaryRegistration: S.SupplementaryRegistration

    private var cancellables: Set<AnyCancellable> = []

    private var cellProvider: (UICollectionView, IndexPath, S.Item) -> UICollectionViewCell? {
        { [weak self] collectionView, indexPath, item in

            guard let self = self else { return nil }

            let cell = S.sections[indexPath.section].cellRegistration(
                cellRegistration: self.cellRegistration,
                collectionView: collectionView,
                indexPath: indexPath,
                item: item
            )

            self.delegate?.didCellDequeud(indexPath: indexPath, cell: cell)

            return cell
        }
    }

    private var supplementaryViewProvider: (UICollectionView, String, IndexPath)
        -> UICollectionReusableView?
    {
        { [weak self] collectionView, kind, indexPath in

            guard let self = self else { return nil }

            let supplementaryView = S.sections[indexPath.section].supplementaryRegistration(
                collectionView: collectionView,
                kind: kind,
                supplementaryRegistration: self.supplementaryRegistration,
                indexPath: indexPath
            )

            self.delegate?.didSupplementaryViewDequeued(
                indexPath: indexPath,
                supplementaryView: supplementaryView
            )

            return supplementaryView
        }
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<S, S.Item> = {
        let dataSource = UICollectionViewDiffableDataSource<S, S.Item>(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
        dataSource.supplementaryViewProvider = supplementaryViewProvider
        return dataSource
    }()

    private let composableLayout: UICollectionViewCompositionalLayout

    public weak var delegate: DiffableCollectionEvent?

    public init(
        cellRegistration: S.CellRegistration,
        supplementaryRegistration: S.SupplementaryRegistration
    ) {
        self.cellRegistration = cellRegistration
        self.supplementaryRegistration = supplementaryRegistration

        self.composableLayout = .init(
            sectionProvider: { section, environment in
                S.sections[section].layout(section: section, environment: environment)
            }
        )
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else { return }
        self.delegate?.didItemSelected(indexPath: indexPath, cell: cell)
    }
}

extension DiffableCollectionUI: UserInterface {
    public func setupView(rootview: UIView) {
        setupCollectionView(rootview: rootview)
    }

    func reload() {
        S.fetchAll
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("finished")
            } receiveValue: { [weak self] allCases in

                guard let self = self else { return }

                var snapshot = NSDiffableDataSourceSnapshot<S, S.Item>()
                snapshot.appendSections(allCases)
                self.dataSource.apply(snapshot, animatingDifferences: true)

                allCases.forEach { section in
                    section.fetch
                        .receive(on: DispatchQueue.main)
                        .sink { _ in
                            print("finished")
                        } receiveValue: { result in
                            if #available(iOS 14.0, *) {
                                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<S.Item>()
                                sectionSnapshot.append(result)
                                self.dataSource.apply(
                                    sectionSnapshot,
                                    to: section,
                                    animatingDifferences: true
                                )
                                self.collectionView.refreshControl?.endRefreshing()
                            } else {
                                fatalError("not supprt under ios 14")
                            }
                        }.store(in: &self.cancellables)
                }
            }.store(in: &self.cancellables)
    }
}

private extension DiffableCollectionUI {
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

        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = .white

        self.collectionView.refreshControl = UIRefreshControl()
        if #available(iOS 14.0, *) {
            self.collectionView.refreshControl?.addAction(.init(handler: { [weak self] _ in
                self?.reload()
            }), for: .valueChanged)
        } else {
            fatalError("not supprt under ios 14")
        }
    }
}
