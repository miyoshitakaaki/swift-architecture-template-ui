import UIKit

open class ListUI<T: List>: NSObject, SegmentedPageContainerProtocol {
    private let list: T

    public init(list: T) {
        self.list = list
    }

    public func setupTopView(view: UIScrollView) {
        self.adjustInsetForSegmentedPageContainer(
            scrollView: view,
            insetTop: self.list.hasSegmentedPageContainer ? 48 : 0,
            offset: self.list.topViewHeight
        )

        guard let topView = list.topView else { return }
        view.addSubviews(
            topView,
            constraints:
            topView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: -self.list.topViewHeight
            ),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topView.heightAnchor.constraint(equalToConstant: self.list.topViewHeight),
            topView.widthAnchor.constraint(equalTo: view.widthAnchor)
        )
    }

    public func setupEmptyView(rootview: UIView) {
        rootview.addSubviews(
            self.list.emptyView,
            constraints:
            self.list.emptyView.topAnchor.constraint(equalTo: rootview.topAnchor),
            self.list.emptyView.bottomAnchor.constraint(equalTo: rootview.bottomAnchor),
            self.list.emptyView.leadingAnchor.constraint(equalTo: rootview.leadingAnchor),
            self.list.emptyView.trailingAnchor.constraint(equalTo: rootview.trailingAnchor)
        )
    }
}
