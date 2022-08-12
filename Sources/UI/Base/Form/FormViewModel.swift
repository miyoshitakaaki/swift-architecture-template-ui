import Combine
import UIKit
import Utility

public final class FormViewModel<T: Form>: ViewModel {
    let loadingState: CurrentValueSubject<LoadingState<T.Input, AppError>, Never> = .init(.standby)
    let loadSubject: PassthroughSubject<Void, Never> = .init()

    private let input: CurrentValueSubject<T.Input, Never> = .init(.init())

    private let isOptional: Bool
    private let fetch: AnyPublisher<T.Input, AppError>
    private let complete: (T.Input) -> AnyPublisher<T.Input, AppError>

    public init(
        isOptional: Bool,
        fetch: AnyPublisher<T.Input, AppError>,
        complete: @escaping (T.Input) -> AnyPublisher<T.Input, AppError>
    ) {
        self.isOptional = isOptional
        self.fetch = fetch
        self.complete = complete
    }

    func bind() -> AnyCancellable {
        self.loadSubject
            .filter { _ in
                if case .loading = self.loadingState.value {
                    return false
                } else {
                    return true
                }
            }
            .handleEvents(receiveOutput: { _ in
                self.loadingState.send(.loading())
            })
            .flatMap { _ in
                self.fetch
                    .handleEvents(receiveOutput: { _ in
                        self.loadingState.send(.standby)
                    }, receiveCompletion: { complete in
                        switch complete {
                        case let .failure(error):
                            self.loadingState.send(.failed(error))
                        case .finished:
                            break
                        }
                    })
                    .replaceError(with: .init())
            }
            .handleEvents(receiveOutput: { _ in self.loadingState.send(.standby) })
            .subscribe(self.input)
    }

    func bind(data: AnyPublisher<T.Input, Never>) -> AnyCancellable {
        data.print().subscribe(self.input)
    }

    func bind(buttonPublisher: AnyPublisher<UIButton, Never>) -> AnyCancellable {
        buttonPublisher
            .handleEvents(receiveOutput: { _ in
                self.loadingState.send(.loading())
            })
            .flatMap { [weak self] _ -> AnyPublisher<LoadingState<T.Input, AppError>, Never> in
                guard let self = self else {
                    return Just(LoadingState<T.Input, AppError>.done(T.Input()))
                        .eraseToAnyPublisher()
                }

                if self.isOptional, self.input.value == T.Input() {
                    return Just(LoadingState<T.Input, AppError>.done(T.Input()))
                        .eraseToAnyPublisher()
                }

                if self.input.value.isValid == false {
                    return Just(
                        LoadingState<T.Input, AppError>
                            .failed(
                                .invalid(
                                    self.input.value.invalidMessage
                                )
                            )
                    )
                    .eraseToAnyPublisher()
                }

                return self.complete(self.input.value)
                    .map(LoadingState<T.Input, AppError>.done)
                    .catch { error in
                        Just(LoadingState<T.Input, AppError>.failed(error))
                    }.eraseToAnyPublisher()
            }
            .subscribe(self.loadingState)
    }
}
