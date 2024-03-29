#if !os(macOS)
import Combine
import UIKit
import Utility

public protocol FormViewModelDelegate: AnyObject {
    func didAlertRequested(alert: UIAlertController)
}

public final class FormViewModel<T: Form>: ViewModel {
    enum FormHandling {
        case optional, invalid, confirmOk, confirmCancel, none
    }

    let loadingState: CurrentValueSubject<LoadingState<T.Input, AppError>, Never> =
        .init(.standby())
    let loadSubject: PassthroughSubject<Void, Never> = .init()

    private let input: CurrentValueSubject<T.Input, Never> = .init(.init())

    private let confirmAlertTitle: String?
    private let isOptional: Bool
    private let fetch: () async -> Result<T.Input, AppError>
    private let complete: (T.Input) async -> Result<T.Input, AppError>

    weak var delegate: FormViewModelDelegate?

    public init(
        confirmAlertTitle: String?,
        isOptional: Bool,
        fetch: @escaping () async -> Result<T.Input, AppError>,
        complete: @escaping (T.Input) async -> Result<T.Input, AppError>
    ) {
        self.confirmAlertTitle = confirmAlertTitle
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
                Future { promise in
                    Task {
                        let result = await self.fetch()

                        self.loadingState.send(.standby())

                        switch result {
                        case let .success(value):
                            self.loadingState.send(.standby())
                            promise(.success(value))

                        case let .failure(error):
                            self.loadingState.send(.failed(error))
                            promise(.success(.init()))
                        }
                    }
                }
            }
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
            .flatMap { _ -> AnyPublisher<FormHandling, Never> in
                if self.isOptional, self.input.value == T.Input() {
                    return Just(FormHandling.optional).eraseToAnyPublisher()
                }

                if self.input.value.isValid == false {
                    return Just(FormHandling.invalid).eraseToAnyPublisher()
                }

                if let title = self.confirmAlertTitle {
                    return Future { promise in

                        let alert = UIAlertController(
                            title: title,
                            message: "",
                            preferredStyle: .alert
                        )

                        alert.addAction(UIAlertAction(
                            title: "キャンセル",
                            style: .default
                        ) { _ in
                            promise(.success(FormHandling.confirmCancel))
                        })

                        alert.addAction(UIAlertAction(
                            title: "OK",
                            style: .default
                        ) { _ in
                            promise(.success(FormHandling.confirmOk))
                        })

                        self.delegate?.didAlertRequested(alert: alert)

                    }.eraseToAnyPublisher()
                }

                return Just(FormHandling.none).eraseToAnyPublisher()
            }
            .flatMap { [weak self] formError -> AnyPublisher<
                LoadingState<T.Input, AppError>,
                Never
            > in
                guard let self else {
                    return Just(LoadingState<T.Input, AppError>.done(T.Input()))
                        .eraseToAnyPublisher()
                }

                switch formError {
                case .optional:
                    return Just(LoadingState<T.Input, AppError>.done(T.Input()))
                        .eraseToAnyPublisher()

                case .invalid:
                    return Just(
                        LoadingState<T.Input, AppError>
                            .failed(
                                .notice(
                                    title: self.input.value.invalidTitle,
                                    message: self.input.value.invalidMessage
                                )
                            )
                    )
                    .eraseToAnyPublisher()

                case .confirmOk:
                    return Future<LoadingState<T.Input, AppError>, Never> { promise in
                        Task {
                            let result = await self.complete(self.input.value)

                            switch result {
                            case let .success(value):
                                promise(.success(.done(value)))
                            case let .failure(error):
                                switch error as AppError {
                                case let .normal(title, message):
                                    promise(
                                        .success(.failed(.notice(
                                            title: title,
                                            message: message
                                        )))
                                    )
                                default:
                                    promise(.success(.failed(error)))
                                }
                            }
                        }
                    }
                    .eraseToAnyPublisher()

                case .confirmCancel:
                    return Just(LoadingState<T.Input, AppError>.standby())
                        .eraseToAnyPublisher()

                case .none:

                    return Future<LoadingState<T.Input, AppError>, Never> { promise in
                        Task {
                            let result = await self.complete(self.input.value)

                            switch result {
                            case let .success(value):
                                promise(.success(.done(value)))
                            case let .failure(error):
                                switch error as AppError {
                                case let .normal(title, message):
                                    promise(
                                        .success(.failed(.notice(
                                            title: title,
                                            message: message
                                        )))
                                    )
                                default:
                                    promise(.success(.failed(error)))
                                }
                            }
                        }
                    }
                    .eraseToAnyPublisher()
                }
            }
            .subscribe(self.loadingState)
    }
}
#endif
