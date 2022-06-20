import Foundation
import UIKit

extension ViewStyle where T: UIButton {
    static var boldMidiumSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        }
    }
}

extension ViewStyle where T: UIScrollView {
    static var vertical: ViewStyle<T> {
        ViewStyle<T> {
            $0.showsVerticalScrollIndicator = false
            $0.scrollRectToVisible($0.frame, animated: true)
            $0.backgroundColor = .clear
        }
    }
}

public func create<T: Form>(
    form: T,
    hideCompletionButton: Bool = false
) -> FormViewController<T> {
    let vc = FormViewController(formType: form)
    vc.inject(
        viewModel: .init(
            isOptional: form.isOptional,
            fetch: form.fetch,
            complete: form.complete
        ),
        ui: .init(
            form: form,
            hideCompletionButton: hideCompletionButton
        )
    )
    return vc
}

public func create<T: FormConfirmUIProtocol & FormConfirmProtocol>(formConfirm: T)
    -> FormConfirmController<T>
{
    let vc = FormConfirmController(form: formConfirm)
    vc.inject(
        viewModel: .init(complete: formConfirm.complete),
        ui: .init(form: formConfirm)
    )
    return vc
}

public func create<T: CollectionList>(collection: T) -> CollectionViewController<T> {
    let vc = CollectionViewController(collection: collection)
    vc.inject(
        viewModel: .init(fetchPublisher: collection.fetchPublisher),
        ui: .init(collection: collection)
    )
    return vc
}

public func create<T: Table>(table: T) -> TableViewController<T> {
    let vc = TableViewController(table: table)
    vc.inject(
        viewModel: .init(fetchPublisher: table.fetchPublisher),
        ui: .init(table: table)
    )
    return vc
}
