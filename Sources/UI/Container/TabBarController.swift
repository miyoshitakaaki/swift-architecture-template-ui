import UIKit
import WebKit

public class TabBarController: UITabBarController {
    private let tintColor: UIColor, badgeTextAttributesForegroundColor: UIColor

    public init(tintColor: UIColor, badgeTextAttributesForegroundColor: UIColor) {
        self.tintColor = tintColor
        self.badgeTextAttributesForegroundColor = badgeTextAttributesForegroundColor
        super.init(nibName: nil, bundle: nil)

        self.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.configureTabBar()
    }

    private func configureTabBar() {
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = UIColor.lightGray
        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
//        tabBarItemAppearance.selected.iconColor = Colors.main
//        tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: Colors.main]
        tabBarItemAppearance.normal.badgeBackgroundColor = .white
        tabBarItemAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.red]
        tabBarItemAppearance.normal.badgePositionAdjustment = UIOffset(horizontal: 4, vertical: 0)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance

//        tabBar.isTranslucent = false
        tabBar.tintColor = self.tintColor
        tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabBarAppearance
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {
    public func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let viewControllers = viewControllers else { return false }

        guard viewController == viewControllers[selectedIndex] else { return true }

        guard let flow = viewController as? (any FlowController) else { return true }

        guard let nav = flow.navigation as? UINavigationController else { return true }

        guard let topController = nav.viewControllers.last else { return true }

        if !topController.isScrolledToTop {
            topController.scrollToTop()
            return false
        } else {
            nav.popViewController(animated: true)
            return true
        }
    }
}

private extension UIViewController {
    func scrollToTop() {
        func scrollToTop(view: UIView?) {
            guard let view = view else { return }

            switch view {
            case let scrollView as UIScrollView:
                if scrollView.scrollsToTop == true {
                    scrollView.setContentOffset(
                        CGPoint(x: 0.0, y: -scrollView.contentInset.top),
                        animated: true
                    )
                    return
                }
            default:
                break
            }

            for subView in view.subviews {
                scrollToTop(view: subView)
            }
        }

        scrollToTop(view: view)
    }

    var isScrolledToTop: Bool {
        for subView in view.subviews {
            if let scrollView = subView as? UIScrollView {
                return (scrollView.contentOffset.y == 0)
            }

            if let webview = subView as? WKWebView {
                return (webview.scrollView.contentOffset.y == 0)
            }
        }

        return true
    }
}
