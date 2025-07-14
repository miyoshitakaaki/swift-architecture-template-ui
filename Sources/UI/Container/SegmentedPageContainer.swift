#if !os(macOS)
import Combine
import Foundation
import UIKit
import Utility

@MainActor
public protocol SegmentedControl: UIControl {
    init(items: [Any]?)
    var selectedSegmentIndex: Int { get set }
    func showBadge(show: Bool, index: Int, number: Int?)
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
    public enum BadgeDisplay {
        case show(number: Int?)
        case hide
    }

    private let tabHeight: CGFloat = 32
    private let margin: CGFloat = 16

    private var vcs: [UIViewController]
    private let tabSegmentedControl: T

    private let tabview: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    public var currentIndex: Int {
        guard let viewController = viewControllers?.first else { return 0 }
        return self.vcs.firstIndex(of: viewController) ?? 0
    }

    private let hidesBarsOnSwipe: Bool

    private let initialIndex: Int

    private var cancellable: Set<AnyCancellable> = []

    public init(
        viewControllers: [UIViewController],
        tabItems: [String],
        hidesBarsOnSwipe: Bool = true,
        initialIndex: Int = 0,
        badgeNotificationName: [Notification.Name?] = [],
        badgePublishers: [AnyPublisher<BadgeDisplay, AppError>] = []
    ) {
        self.vcs = viewControllers
        self.tabSegmentedControl = T(items: tabItems)
        self.hidesBarsOnSwipe = hidesBarsOnSwipe
        self.initialIndex = initialIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        badgePublishers.enumerated().forEach { index, publisher in
            publisher
                .receive(on: DispatchQueue.main)
                .sink { _ in
                } receiveValue: { [weak self] badge in

                    guard let self else { return }

                    switch badge {
                    case let .show(number):
                        self.showBadge(show: true, index: index, number: number)
                    case .hide:
                        self.showBadge(show: false, index: index, number: nil)
                    }
                }.store(in: &self.cancellable)
        }

        badgeNotificationName.enumerated().forEach { index, name in
            guard let name else { return }

            NotificationCenter.default
                .addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    guard let self else { return }

                    badgePublishers[safe: index]?
                        .receive(on: DispatchQueue.main)
                        .sink { complete in
                            print(complete)
                        } receiveValue: { result in

                            switch result {
                            case let .show(number):
                                self.showBadge(show: true, index: index, number: number)

                            case .hide:
                                self.showBadge(show: false, index: index, number: nil)
                            }
                        }
                        .store(in: &self.cancellable)
                }
        }
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
            self.tabSegmentedControl,

            constraints:
            self.tabview.rightAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.rightAnchor
            ),
            self.tabview.leftAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leftAnchor
            ),
            self.tabview.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tabview.bottomAnchor.constraint(
                equalTo: self.tabSegmentedControl.bottomAnchor,
                constant: self.margin
            ),

            self.tabSegmentedControl.topAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.tabSegmentedControl.rightAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.rightAnchor,
                constant: -self.margin
            ),
            self.tabSegmentedControl.leftAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leftAnchor,
                constant: self.margin
            ),
            self.tabSegmentedControl.heightAnchor.constraint(equalToConstant: self.tabHeight)
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

        self.tabSegmentedControl.addTarget(
            self,
            action: #selector(Self.segmentChanged(sender:)),
            for: .valueChanged
        )

        self.selectTab(index: self.initialIndex, animated: false)
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
    }

    public func selectTab(index: Int, animated: Bool) {
        self.tabSegmentedControl.selectedSegmentIndex = index
        let direction: UIPageViewController
            .NavigationDirection = index > self.currentIndex ? .forward : .reverse
        self.setViewControllers([self.vcs[index]], direction: direction, animated: animated)
    }

    public func setViewControllers(vcs: [UIViewController]) {
        self.vcs = vcs
    }

    public func showBadge(show: Bool, index: Int, number: Int?) {
        self.tabSegmentedControl.showBadge(show: show, index: index, number: number)
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
        self.tabSegmentedControl.selectedSegmentIndex = index
    }
}
#endif
