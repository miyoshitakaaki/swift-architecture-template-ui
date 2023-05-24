import UIKit

@MainActor
public protocol VCInjectable: ViewController {
    associatedtype VM: ViewModel
    associatedtype UI: UserInterface

    var viewModel: VM! { get set }
    var ui: UI! { get set }

    func inject(
        viewModel: VM,
        ui: UI
    )
}

public extension VCInjectable {
    func inject(
        viewModel: VM,
        ui: UI
    ) {
        self.viewModel = viewModel
        self.ui = ui
    }

    func setupNavigationBar(content: NavigationContent) {
        func setup(target: UIViewController) {
            target.navigationItem.rightBarButtonItems = content.rightNavigationItems
            target.navigationItem.leftBarButtonItems = content.leftNavigationItems
            self.setupNavigationTitle(content.title)
            target.navigationItem.rightBarButtonItem?.tintColor = content
                .rightBarButtonItemTintColor
            target.navigationItem.leftBarButtonItem?.tintColor = content.leftBarButtonItemTintColor
        }

        if self.parent is UIPageViewController {
            setup(target: self)
        } else if self.parent is UINavigationController {
            setup(target: self)
        } else {
            setup(target: self.parent ?? self)
        }
    }

    func setupNavigationTitle(_ title: String?) {
        func setup(target: UIViewController) {
            if let title {
                target.navigationItem.titleView = UILabel(style: .init(style: { label in
                    label.font = .systemFont(ofSize: 17, weight: .semibold)
                }), title: title)
            } else {
                target.navigationItem.titleView = UIView()
            }
        }

        if self.parent is UIPageViewController {
            setup(target: self)
        } else if self.parent is UINavigationController {
            setup(target: self)
        } else {
            setup(target: self.parent ?? self)
        }
    }
}
