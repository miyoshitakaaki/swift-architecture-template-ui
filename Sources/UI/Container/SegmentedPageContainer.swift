import Foundation
import Combine
import UIKit

public protocol SegmentedControl: UIControl {
    init(items: [Any]?)
    var selectedSegmentIndex: Int { get set }
    func showBadge(show: Bool, index: Int)
}

public protocol SegmentedPageContainerProtocol {
    func adjustInsetForSegmentedPageContainer(
        scrollView: UIScrollView,
        insetTop: CGFloat,
        offset: CGFloat
    )
}

public extension SegmentedPageContainerProtocol {
    func adjustInsetForSegmentedPageContainer(
        scrollView: UIScrollView,
        insetTop: CGFloat = 48,
        offset: CGFloat = 0
    ) {
        scrollView.contentInset.top = insetTop + offset
        scrollView.verticalScrollIndicatorInsets.top = insetTop
    }
}

open class SegmentedPageContainer<T: SegmentedControl>: UIPageViewController,
    UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    private let tabHeight: CGFloat = 32
    private let margin: CGFloat = 16

    private var vcs: [UIViewController]
    private let tab: T

    public var cancellable = Set<AnyCancellable>()

    private let tabview: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    public var currentIndex: Int {
        guard let viewController = viewControllers?.first else { return 0 }
        return self.vcs.firstIndex(of: viewController) ?? 0
    }

    /// 表示中の画面インデックスが変わったとき、新しいIndexを通知する
    /// UISegmentControlとUIPageControllerどちらのイベントも流れる
    ///
    /// e.g.
    /// ```
    /// didChangeSelectedIndexSubject
    ///     .removeDuplicates() // 同じ値の通知重複は無視
    ///     .sink { newIndex in
    ///         print("新しいindexは\(newIndex)")
    ///     }
    ///     .store(in: &self.cancellable)
    ///
    public var didChangeSelectedIndexSubject: PassthroughSubject<Int, Never> = .init()

    private let hidesBarsOnSwipe: Bool

    public init(
        viewControllers: [UIViewController],
        tabItems: [String],
        hidesBarsOnSwipe: Bool = true
    ) {
        self.vcs = viewControllers
        self.tab = T(items: tabItems)
        self.hidesBarsOnSwipe = hidesBarsOnSwipe
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("no need to implement")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubviews(
            self.tabview,
            self.tab,

            constraints:
            self.tabview.rightAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.rightAnchor
            ),
            self.tabview.leftAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leftAnchor
            ),
            self.tabview.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tabview.bottomAnchor.constraint(
                equalTo: self.tab.bottomAnchor,
                constant: self.margin
            ),

            self.tab.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.tab.rightAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.rightAnchor,
                constant: -self.margin
            ),
            self.tab.leftAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leftAnchor,
                constant: self.margin
            ),
            self.tab.heightAnchor.constraint(equalToConstant: self.tabHeight)
        )

        self.setViewControllers(
            {
                if let vc = vcs.first {
                    return [vc]
                } else {
                    return []
                }
            }(),
            direction: .forward,
            animated: true
        )

        self.dataSource = self
        self.delegate = self

        self.tab.selectedSegmentIndex = 0

        self.tab.addTarget(
            self,
            action: #selector(Self.segmentChanged(sender:)),
            for: .valueChanged
        )
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = self.hidesBarsOnSwipe
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = !self.hidesBarsOnSwipe
    }

    @objc func segmentChanged(sender: AnyObject) {
        guard
            let selectedIndex = (sender as? SegmentedControl)?.selectedSegmentIndex else { return }
        let direction: UIPageViewController
            .NavigationDirection = selectedIndex > self.currentIndex ? .forward : .reverse
        self.setViewControllers([self.vcs[selectedIndex]], direction: direction, animated: true)
        // UISegmentControlによってページを切り替えられた
        self.didChangeSelectedIndexSubject.send(selectedIndex)
    }

    public func selectTab(index: Int, animated: Bool) {
        self.tab.selectedSegmentIndex = index
        let direction: UIPageViewController
            .NavigationDirection = index > self.currentIndex ? .forward : .reverse
        self.setViewControllers([self.vcs[index]], direction: direction, animated: animated)
    }

    public func setViewControllers(vcs: [UIViewController]) {
        self.vcs = vcs
    }

    public func showBadge(show: Bool, index: Int) {
        self.tab.showBadge(show: show, index: index)
    }

    public func presentationCount(for pageViewController: UIPageViewController) -> Int { self.vcs
        .count
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if let index = self.vcs.firstIndex(of: viewController), index > 0 {
            return self.vcs[index - 1]
        } else {
            return nil
        }
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if let index = self.vcs.firstIndex(of: viewController), index < self.vcs.count - 1 {
            return self.vcs[index + 1]
        } else {
            return nil
        }
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            let vc = viewControllers?.first,
            let index = self.vcs.firstIndex(of: vc) else { return }
        self.tab.selectedSegmentIndex = index

        // 画面のスワイプでページが切り替えられた
        self.didChangeSelectedIndexSubject.send(index)
    }
}
