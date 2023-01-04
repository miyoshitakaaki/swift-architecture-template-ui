import Combine
import UIKit

@MainActor
public protocol VCInjectable: ViewController {
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
        let target = (self.parent as? (any FlowController)) ?? self

        target.navigationItem.rightBarButtonItems = content.rightNavigationItems
        target.navigationItem.leftBarButtonItems = content.leftNavigationItems

        self.setupNavigationTitle(content.title)

        target.navigationItem.rightBarButtonItem?.tintColor = content.rightBarButtonItemTintColor
        target.navigationItem.leftBarButtonItem?.tintColor = content.leftBarButtonItemTintColor
    }

    func setupNavigationTitle(_ title: String?) {
        let target = (self.parent as? (any FlowController)) ?? self

        if let title {
            target.navigationItem.titleView = UILabel(style: .init(style: { label in
                label.font = .systemFont(ofSize: 17, weight: .semibold)
            }), title: title)
        } else {
            target.navigationItem.titleView = UIView()
        }
    }
}
