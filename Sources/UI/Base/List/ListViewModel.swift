import Combine
import UIKit
import Utility

public struct ListSection<T: Equatable, HeaderItem: Equatable, FooterItem: Equatable>: Equatable
    where HeaderItem: Hashable, FooterItem: Hashable
{
    public struct Section: Equatable, Hashable {
        public let header: HeaderItem
        public let footer: FooterItem

        public init(header: HeaderItem, footer: FooterItem) {
            self.header = header
            self.footer = footer
        }
    }

    public let section: Section
    public var items: [T]

    public init(section: Section, items: [T]) {
        self.section = section
        self.items = items
    }
}

public final class ListViewModel<
    T: Hashable,
    Parameter,
    HeaderItem: Equatable,
    FooterItem: Equatable
>: ViewModel where HeaderItem: Hashable, FooterItem: Hashable {
    public typealias Items = [ListSection<T, HeaderItem, FooterItem>]

    public let loadSubject: PassthroughSubject<(parameter: Parameter?, isAdditional: Bool), Never> =
        .init()
    public let loadingState: CurrentValueSubject<LoadingState<Items, AppError>, Never> =
        .init(.standby())

    private let fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError>

    public init(
        fetchPublisher: @escaping ((parameter: Parameter?, isAdditional: Bool))
            -> AnyPublisher<Items, AppError>
    ) {
        self.fetchPublisher = fetchPublisher
    }

    public func bind() -> AnyCancellable {
        self.loadSubject
            .filter { _ in
                if case .loading = self.loadingState.value {
                    return false
                } else {
                    return true
                }
            }
            .handleEvents(receiveOutput: { _ in
                self.loadingState.send(.loading(self.loadingState.value.value))
            })
            .flatMap { [weak self] query -> AnyPublisher<LoadingState<Items, AppError>, Never> in

                guard let self = self else {
                    return Just(LoadingState<Items, AppError>.failed(.unknown))
                        .eraseToAnyPublisher()
                }

                return self.fetchPublisher(query)
                    .map { new in
                        let current = self.loadingState.value.value ?? []

                        if query.isAdditional {
                            if new.isEmpty {
                                return LoadingState<Items, AppError>.standby(current)
                            } else {
                                let result = new.reduce(current) { partialResult, item in
                                    var sections = partialResult

                                    let index = sections.firstIndex { section in
                                        section.section == item.section
                                    }

                                    if let index {
                                        sections[index].items += item.items
                                    } else {
                                        sections.append(item)
                                    }

                                    return sections
                                }
                                return LoadingState<Items, AppError>.done(result)
                            }
                        } else {
                            if new.isEmpty {
                                return LoadingState<Items, AppError>.done([])
                            } else {
                                return LoadingState<Items, AppError>.done(new)
                            }
                        }
                    }
                    .catch { error in
                        Just(LoadingState<Items, AppError>.failed(error))
                    }
                    .eraseToAnyPublisher()
            }
            .subscribe(self.loadingState)
    }
}
