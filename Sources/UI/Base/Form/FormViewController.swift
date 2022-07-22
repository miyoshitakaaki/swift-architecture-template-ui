import Combine
import UIKit

public protocol FormViewControllerDelegate: AnyObject {
    func didCompletionButtonTapped<T>(data: T)
}

extension FormViewController: VCInjectable {
    public typealias VM = FormViewModel<T>
    public typealias UI = FormUI
}

// MARK: - stored properties

public final class FormViewController<T: Form>: UIViewController, ActivityPresentable,
    AlertPresentable
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    /// 画面を閉じる時に呼ばれる
    /// 戻るボタンのイベントとして扱う 閉じるボタンは拾えない
    public let willDismissFromParent: PassthroughSubject<Void, Never> = .init()

    public weak var delegate: FormViewControllerDelegate?

    private let formType: T!

    public init(formType: T) {
        self.formType = formType
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        title = self.formType.title

        self.ui.setupView(rootview: view)
        self.ui.setupNavigationBar(navigationBar: nil, navigationItem: navigationItem)

        setupEvent()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tabBarController?.tabBar.isHidden = true

        self.viewModel.loadSubject.send()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false

        if self.isMovingFromParent {
            self.willDismissFromParent.send(())
        }
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

        self.viewModel.bind(buttonPublisher: self.ui.completionButtonPublisher)
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
                    self.present(error)

                case let .done(value):
                    self.dismissActivity()
                    self.delegate?.didCompletionButtonTapped(data: value)

                case .addtionalDone:
                    break
                }
            }).store(in: &self.cancellables)
    }
}
