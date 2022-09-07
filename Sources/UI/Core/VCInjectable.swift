import Combine
import UIKit

public protocol VCInjectable: UIViewController {
    associatedtype VM: ViewModel
    associatedtype UI: UserInterface

    var viewModel: VM! { get set }
    var ui: UI! { get set }
    var cancellables: Set<AnyCancellable> { get set }

    func inject(
        viewModel: VM,
        ui: UI,
        cancellables: Set<AnyCancellable>
    )
}

public extension VCInjectable {
    func inject(
        viewModel: VM,
        ui: UI,
        cancellables: Set<AnyCancellable> = []
    ) {
        self.viewModel = viewModel
        self.ui = ui
        self.cancellables = cancellables
    }

    func setupNavigationBar(content: NavigationContent) {
        self.navigationItem.rightBarButtonItems = content.rightNavigationItems
        self.navigationItem.leftBarButtonItems = content.leftNavigationItems

        if let title = content.title {
            self.title = title
        } else {
            self.navigationItem.titleView = UIView()
        }

        self.navigationItem.rightBarButtonItem?.tintColor = content.rightBarButtonItemTintColor
        self.navigationItem.leftBarButtonItem?.tintColor = content.leftBarButtonItemTintColor
    }
}
