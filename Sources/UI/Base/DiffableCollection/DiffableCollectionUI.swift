import Combine
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
                return sectionItem.layout(
                    section: section,
                    environment: environment,
                    items: items,
                    pagingInfoSubject: self.pagingInfoSubject
                )
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
        dataSource.supplementaryViewProvider = self.supplementaryViewProvider
        return dataSource
    }()

    public weak var delegate: (any DiffableCollectionEvent)?
    public weak var uiDelegate: DiffableCollectionUIDelegate?

    private let cellRegistration: S.CellRegistration
    private let supplementaryRegistration: S.SupplementaryRegistration
    private let pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    private let pageControlSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    private let bottomFixedView: BottomFixedViewProtocol?
    private var cancellable: Set<AnyCancellable> = []

    public init(
        cellRegistration: S.CellRegistration,
        supplementaryRegistration: S.SupplementaryRegistration,
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>,
        pageControlSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>,
        bottomFixedView: BottomFixedViewProtocol? = nil
    ) {
        self.cellRegistration = cellRegistration
        self.supplementaryRegistration = supplementaryRegistration
        self.pagingInfoSubject = pagingInfoSubject
        self.pageControlSubject = pageControlSubject
        self.bottomFixedView = bottomFixedView
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
        self.setupCollectionView(rootview: rootview)
        self.setupBottomFixedView(rootView: rootview)
    }

    func bind() {
        self.pageControlSubject.sink { info in

            let visiableItems = self.collectionView.indexPathsForVisibleItems
                .filter { $0.section == info.sectionIndex }
                .sorted()

            if
                let nextIndexPath = visiableItems.last,
                let nextCell = self.collectionView.cellForItem(at: nextIndexPath),
                let horizontalScrollView = nextCell.superview as? UIScrollView
            {
                let x: CGFloat = {
                    if #available(iOS 15, *) {
                        return info.isFirstIndex
                            ? info.offset
                            : nextCell.frame.origin.x - info.offset
                    } else {
                        return info.isFirstIndex
                            ? -info.offset
                            : nextCell.frame.origin.x + info.offset
                    }
                }()

                horizontalScrollView.scrollRectToVisible(
                    .init(
                        x: x,
                        y: nextCell.frame.origin.y,
                        width: nextCell.frame.width,
                        height: nextCell.frame.height
                    ),
                    animated: true
                )
            }
        }.store(in: &self.cancellable)
    }

    func setupBottomAnchor(hasTabber: Bool, rootview: UIView) {
        if hasTabber {
            if let view = self.bottomFixedView {
                self.collectionView.bottomAnchor
                    .constraint(equalTo: view.topAnchor).isActive = true
            } else {
                self.collectionView.bottomAnchor
                    .constraint(equalTo: rootview.safeAreaLayoutGuide.bottomAnchor).isActive = true
            }
        } else {
            self.collectionView.bottomAnchor
                .constraint(equalTo: rootview.bottomAnchor).isActive = true
        }
    }

    func setItems(section: S, fetchRemote: Bool) {
        Task {
            let result = await section.fetch(fetchRemote: fetchRemote)

            switch result {
            case let .success(result):
                var snapshot = self.dataSource.snapshot()
                snapshot.appendItems(result, toSection: section)
                self.dataSource.apply(snapshot, animatingDifferences: false)
                self.collectionView.refreshControl?.endRefreshing()

            case let .failure(error):
                self.delegate?.didErrorOccured(error: error)
            }
        }
    }

    func setSections(
        pullToRefresh: Bool = false,
        fetchRemote: Bool = true,
        completion: @escaping (Result<[S], AppError>) -> Void
    ) {
        self.bottomFixedView?.reload()

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
    func setupCollectionView(rootview: UIView) {
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
            self?.setSections(pullToRefresh: true, fetchRemote: true) { [weak self] result in

                switch result {
                case let .success(sections):
                    sections.forEach { [weak self] section in
                        self?.setItems(section: section, fetchRemote: true)
                    }

                case .failure:
                    break
                }
            }
        }), for: .valueChanged)
    }

    func setupBottomFixedView(rootView: UIView) {
        if let view = self.bottomFixedView {
            rootView.addSubviews(
                view,
                constraints:
                view.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor)
            )
        }
    }
}
