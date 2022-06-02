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
}
