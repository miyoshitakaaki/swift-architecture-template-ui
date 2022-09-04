import Foundation
import UIKit

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

public func create<T: CollectionList>(
    collection: T,
    content: T.NavContent
) -> CollectionViewController<T, T.NavContent> {
    let vc = CollectionViewController(collection: collection, content: content)
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
