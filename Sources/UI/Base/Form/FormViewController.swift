import Combine
import UIKit
import Utility

public protocol FormViewControllerDelegate: AnyObject {
    func didCompletionButtonTapped<F: Form>(data: F.Input, form: F)
    func didErrorOccured(error: AppError)
}

extension FormViewController: VCInjectable {
    public typealias VM = FormViewModel<T>
    public typealias UI = FormUI
}

// MARK: - stored properties

public final class FormViewController<T: Form>: ViewController, ActivityPresentable {
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    public weak var delegate: FormViewControllerDelegate?

    private let formType: T
    private let content: T.NavContent

    override public var screenNameForAnalytics: String {
        self.formType.screenNameForAnalytics
    }

    override public var screenEventForAnalytics: [AnalyticsEvent] {
        self.formType.screenEventForAnalytics
    }

    public init(formType: T, content: T.NavContent) {
        self.formType = formType
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar(content: self.content)
        self.ui.setupView(rootview: view)
        self.ui.setupNavigationBar(navigationBar: nil, navigationItem: navigationItem)

        setupEvent()

        self.viewModel.loadSubject.send()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tabBarController?.tabBar.isHidden = true
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false
    }
}

// MARK: - private methods

private extension FormViewController {
    func setupEvent() {
        self.ui.bindCompleteButton().store(in: &self.cancellables)

        self.formType.data
            .map { T.Input() == $0 }
            .sink { [weak self] isEmpty in
                self?.ui.chanegCompleteButtonTitleIfNeeded(isEmpty: isEmpty)
            }
            .store(in: &self.cancellables)

        self.viewModel.bind(data: self.formType.data)
            .store(in: &self.cancellables)

        self.viewModel.bind(
            buttonPublisher: self.ui.completionButtonPublisher
                .flatMap { [weak self] _ -> AnyPublisher<Bool, Never> in

                    if let title = self?.formType.confirmAlertTitle {
                        return Future { promise in
                            let alert = UIAlertController(
                                title: title,
                                message: "",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(
                                title: "OK",
                                style: .default
                            ) { _ in
                                promise(.success(true))
                            })
                            alert.addAction(UIAlertAction(
                                title: "キャンセル",
                                style: .default
                            ) { _ in
                                promise(.success(false))
                            })
                            self?.present(alert, animated: true)
                        }.eraseToAnyPublisher()
                    } else {
                        return Just(true).eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        )
        .store(in: &self.cancellables)

        self.viewModel.bind()
            .store(in: &self.cancellables)

        self.viewModel.loadingState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in

                guard let self = self else { return }
                switch state {
                case .standby:
                    self.dismissActivity()

                case .loading:
                    self.presentActivity()

                case let .failed(error):
                    self.dismissActivity()
                    self.delegate?.didErrorOccured(error: error)

                case let .done(value):
                    self.dismissActivity()
                    self.delegate?.didCompletionButtonTapped(data: value, form: self.formType)

                case .addtionalDone:
                    break
                }
            }).store(in: &self.cancellables)
    }
}
