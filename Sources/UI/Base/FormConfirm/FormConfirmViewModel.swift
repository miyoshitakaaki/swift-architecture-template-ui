import Combine
import UIKit
import Utility

public final class FormConfirmViewModel<T: Equatable>: ViewModel {
    let loadingState: CurrentValueSubject<LoadingState<T, AppError>, Never> = .init(.standby())

    private let complete: () async -> Result<T, AppError>

    public init(complete: @escaping () async -> Result<T, AppError>) {
        self.complete = complete
    }

    func bind(buttonPublisher: AnyPublisher<UIButton, Never>) -> AnyCancellable {
        buttonPublisher
            .handleEvents(receiveOutput: { _ in
                self.loadingState.send(.loading())
            })
            .flatMap { [weak self] _ -> AnyPublisher<LoadingState<T, AppError>, Never> in

                guard let self else {
                    return Just(LoadingState<T, AppError>.failed(.none))
                        .eraseToAnyPublisher()
                }

                return Future<LoadingState<T, AppError>, Never> { promise in
                    Task {
                        let result = await self.complete()

                        switch result {
                        case let .success(value):
                            promise(.success(LoadingState<T, AppError>.done(value)))
                        case let .failure(error):
                            promise(.success(LoadingState<T, AppError>.failed(error)))
                        }
                    }
                }.eraseToAnyPublisher()
            }
            .subscribe(self.loadingState)
    }
}
