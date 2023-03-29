import Foundation
import UIKit
import Utility

public protocol DiffableCollectionUIDelegate: AnyObject {
    func willfetchAll(pullToRefresh: Bool)
    func didfetchAll()
}

@MainActor
public final class DiffableCollectionUI<
    S: DiffableCollectionSection
>: NSObject,
    UICollectionViewDelegate
{
    private lazy var collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout(
            sectionProvider: { [weak self] section, environment in

                guard let self else { return nil }

                let snapShot = self.dataSource.snapshot()
                let sectionItem = snapShot.sectionIdentifiers[section]
                let items = snapShot.itemIdentifiers(inSection: sectionItem)
                return sectionItem.layout(section: section, environment: environment, items: items)
            }
        )
    )

    private var cellProvider: (UICollectionView, IndexPath, S.Item) -> UICollectionViewCell? {
        { [weak self] collectionView, indexPath, item in

            guard let self else { return nil }

            let cell = S.sections[indexPath.section].cellRegistration(
                cellRegistration: self.cellRegistration,
                collectionView: collectionView,
                indexPath: indexPath,
                item: item
            )

            (cell as? (any CollectionLayout))?.indexPath = indexPath

            return cell
        }
    }

    private var supplementaryViewProvider: (UICollectionView, String, IndexPath)
        -> UICollectionReusableView?
    {
        { [weak self] collectionView, kind, indexPath in

            guard let self else { return nil }

            let supplementaryView = S.sections[indexPath.section].supplementaryRegistration(
                collectionView: collectionView,
                kind: kind,
                supplementaryRegistration: self.supplementaryRegistration,
                indexPath: indexPath
            )

            (supplementaryView as? (any DiffableCollectionSupplementaryLayout))?
                .indexPath = indexPath

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

    public weak var delegate: (any DiffableCollectionEvent)?
    public weak var uiDelegate: DiffableCollectionUIDelegate?

    private let cellRegistration: S.CellRegistration
    private let supplementaryRegistration: S.SupplementaryRegistration

    public init(
        cellRegistration: S.CellRegistration,
        supplementaryRegistration: S.SupplementaryRegistration
    ) {
        self.cellRegistration = cellRegistration
        self.supplementaryRegistration = supplementaryRegistration
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

    func setupBottomAnchor(hasTabber: Bool, rootview: UIView) {
        if hasTabber {
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.bottomAnchor).isActive = true
        }
    }

    func reloadSection(section: S, fetchRemote: Bool) {
        Task {
            let result = await section.fetch(fetchRemote: fetchRemote)

            switch result {
            case let .success(result):
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadSections([section])
                snapshot.appendItems(result, toSection: section)
                self.dataSource.apply(snapshot, animatingDifferences: false)
                self.collectionView.refreshControl?.endRefreshing()

            case let .failure(error):
                self.delegate?.didErrorOccured(error: error)
            }
        }
    }

    func reload(
        pullToRefresh: Bool = false,
        fetchRemote: Bool = true,
        completion: @escaping (Result<[S], AppError>) -> Void
    ) {
        self.uiDelegate?.willfetchAll(pullToRefresh: pullToRefresh)

        Task {
            let result = await S.reload(fetchRemote: fetchRemote)

            self.collectionView.refreshControl?.endRefreshing()
            self.uiDelegate?.didfetchAll()

            switch result {
            case let .success(allCases):
                var snapshot = NSDiffableDataSourceSnapshot<S, S.Item>()
                snapshot.appendSections(allCases)
                self.dataSource.apply(snapshot, animatingDifferences: false)
                completion(.success(allCases))

            case let .failure(error):
                self.delegate?.didErrorOccured(error: error)
                completion(.failure(error))
            }
        }
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
            self.collectionView.trailingAnchor
                .constraint(equalTo: rootview.safeAreaLayoutGuide.trailingAnchor)
        )

        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = .white

        if S.pullToRefreshable {
            self.collectionView.refreshControl = UIRefreshControl()
        }

        self.collectionView.refreshControl?.addAction(.init(handler: { [weak self] _ in
            self?.reload(pullToRefresh: true, fetchRemote: true) { [weak self] result in

                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.reloadSection(section: section, fetchRemote: true)
                    }

                case .failure:
                    break
                }
            }
        }), for: .valueChanged)
    }
}
