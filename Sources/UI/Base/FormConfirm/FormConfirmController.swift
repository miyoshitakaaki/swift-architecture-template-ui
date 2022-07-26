import Combine
import UIKit

public protocol FormConfirmControllerDelegate: AnyObject {
    func didConfirmCompletionButtonTapped<T>(data: T)
}

extension FormConfirmController: VCInjectable {
    public typealias VM = FormConfirmViewModel<T.OutputType>
    public typealias UI = FormConfirmUI
}

// MARK: - stored properties

public final class FormConfirmController<T: FormConfirmProtocol>: UIViewController,
    ActivityPresentable,
    AlertPresentable
{
    public var viewModel: VM!
    public var ui: UI!
    public var cancellables: Set<AnyCancellable> = []

    /// 画面を閉じる時に呼ばれる
    /// 戻るボタンのイベントとして扱う 閉じるボタンは拾えない
    public let willDismissFromParent: PassthroughSubject<Void, Never> = .init()

    public weak var delegate: FormConfirmControllerDelegate?

    private let form: T

    public init(form: T) {
        self.form = form
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        title = self.form.title
        view.backgroundColor = .white

        self.ui.setupView(rootview: view)

        self.viewModel
            .bind(buttonPublisher: self.ui.completionButtonPublisher)
            .store(in: &self.cancellables)

        self.viewModel.loadingState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in

                guard let self = self else { return }
                switch state {
                case .standby:
                    break

                case .loading:
                    self.presentActivity()

                case let .failed(error):
                    self.dismissActivity()
                    self.present(error)

                case let .done(value):
                    self.dismissActivity()
                    self.delegate?.didConfirmCompletionButtonTapped(data: value)

                case .addtionalDone:
                    break
                }
            }).store(in: &self.cancellables)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tabBarController?.tabBar.isHidden = true
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tabBarController?.tabBar.isHidden = false

        if self.isMovingFromParent {
            self.willDismissFromParent.send(())
        }
    }
}
