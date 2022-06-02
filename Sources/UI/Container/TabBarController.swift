import UIKit

public class TabBarController: UITabBarController {
    private let tintColor: UIColor, badgeTextAttributesForegroundColor: UIColor

    public init(tintColor: UIColor, badgeTextAttributesForegroundColor: UIColor) {
        self.tintColor = tintColor
        self.badgeTextAttributesForegroundColor = badgeTextAttributesForegroundColor
        super.init(nibName: nil, bundle: nil)
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
