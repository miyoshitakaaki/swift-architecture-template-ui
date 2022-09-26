import Combine
import UIKit
import Utility

public final class FormConfirmViewModel<T: Equatable>: ViewModel {
    let loadingState: CurrentValueSubject<LoadingState<T, AppError>, Never> = .init(.standby())

    private let complete: AnyPublisher<T, AppError>

    public init(complete: AnyPublisher<T, AppError>) {
        self.complete = complete
    }

    func bind(buttonPublisher: AnyPublisher<UIButton, Never>) -> AnyCancellable {
        buttonPublisher
            .handleEvents(receiveOutput: { _ in
                self.loadingState.send(.loading())
            })
            .flatMap { [weak self] _ -> AnyPublisher<LoadingState<T, AppError>, Never> in

                guard let self = self else {
                    return Just(LoadingState<T, AppError>.failed(.none))
                        .eraseToAnyPublisher()
                }

                return self.complete
                    .map(LoadingState<T, AppError>.done)
                    .catch { error in
                        Just(LoadingState<T, AppError>.failed(error))
                    }
                    .eraseToAnyPublisher()
            }
            .subscribe(self.loadingState)
    }
}
