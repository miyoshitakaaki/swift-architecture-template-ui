import Combine
import Foundation
import UIKit
import Utility

@MainActor
public func create<T: Form>(
    form: T,
    navContent: T.NavContent,
    hideCompletionButton: Bool = false
) -> FormViewController<T> {
    let vc = FormViewController(formType: form, content: navContent)
    vc.inject(
        viewModel: .init(
            confirmAlertTitle: form.confirmAlertTitle,
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

@MainActor
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

@MainActor
public func create<T: CollectionList>(
    collection: T,
    content: T.NavContent,
    needRefreshNotificationNames: [Notification.Name] = []
) -> CollectionViewController<T, T.NavContent> {
    let vc = CollectionViewController(
        collection: collection,
        content: content,
        needRefreshNotificationNames: needRefreshNotificationNames
    )
    vc.inject(
        viewModel: .init(fetch: collection.fetch),
        ui: .init(collection: collection)
    )
    return vc
}

@MainActor
public func create<T: Table>(
    table: T,
    content: T.NavContent,
    needRefreshNotificationNames: [Notification.Name] = []
) -> TableViewController<T> {
    let vc = TableViewController(
        table: table,
        content: content,
        needRefreshNotificationNames: needRefreshNotificationNames
    )
    vc.inject(
        viewModel: .init(fetch: table.fetch),
        ui: .init(table: table)
    )
    return vc
}

@MainActor
public func create<T: DiffableCollectionSection, N: NavigationContent>(
    type: T.Type,
    initialReloadType: ReloadType,
    content: N,
    screenNameForAnalytics: [AnalyticsScreen],
    screenEventForAnalytics: [AnalyticsEvent],
    needRefreshNotificationNames: [Notification.Name],
    needForceRefreshNotificationNames: [Notification.Name],
    delegate: any DiffableCollectionEvent
) -> DiffableCollectionViewController<T, N> {
    let vc = DiffableCollectionViewController<T, N>(
        initialReloadType: initialReloadType,
        content: content,
        screenNameForAnalytics: screenNameForAnalytics,
        screenEventForAnalytics: screenEventForAnalytics,
        needRefreshNotificationNames: needRefreshNotificationNames,
        needForceRefreshNotificationNames: needForceRefreshNotificationNames
    )

    let pagingInfoSubject = PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>()

    let ui = DiffableCollectionUI<T>.init(
        cellRegistration: .init(),
        supplementaryRegistration: .init(pagingInfoSubject: pagingInfoSubject),
        pagingInfoSubject: pagingInfoSubject
    )
    ui.delegate = delegate
    vc.inject(viewModel: .init(), ui: ui)

    return vc
}
