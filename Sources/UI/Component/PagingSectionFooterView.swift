import Combine
import UIKit

public class PagingSectionFooterView: UICollectionReusableView {
    public struct InitialPagingInfo {
        public let count: Int
        public let section: Int

        public init(count: Int, section: Int) {
            self.count = count
            self.section = section
        }
    }

    public struct PagingInfo: Equatable, Hashable {
        let sectionIndex: Int
        let currentPage: Int

        public init(sectionIndex: Int, currentPage: Int) {
            self.sectionIndex = sectionIndex
            self.currentPage = currentPage
        }
    }

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isUserInteractionEnabled = true
        control.currentPageIndicatorTintColor = .systemOrange
        control.pageIndicatorTintColor = .systemGray5
        return control
    }()

    private var cancellable: Set<AnyCancellable> = []

    private var subject: PassthroughSubject<PagingInfo, Never>?, section: Int?

    private var pageControlsubject: PassthroughSubject<PagingInfo, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }

    public func configure(with numberOfPages: Int) {
        self.pageControl.numberOfPages = numberOfPages
    }

    public func subscribeTo(
        subject: PassthroughSubject<PagingInfo, Never>,
        pageControlsubject: PassthroughSubject<PagingInfo, Never>,
        for section: Int
    ) {
        self.subject = subject
        self.section = section
        self.pageControlsubject = pageControlsubject

        subject
            .filter { $0.sectionIndex == section }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pagingInfo in
                guard let self else { return }

                if self.pageControl.currentPage != pagingInfo.currentPage {
                    self.pageControl.currentPage = pagingInfo.currentPage
                }
            }.store(in: &self.cancellable)
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(self.pageControl)

        NSLayoutConstraint.activate([
            self.pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.pageControl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        self.pageControl.addTarget(
            self,
            action: #selector(self.pageControlValueChanged),
            for: .valueChanged
        )
    }

    @objc private func pageControlValueChanged() {
        self.pageControlsubject?
            .send(.init(sectionIndex: self.section!, currentPage: self.pageControl.currentPage))
    }
}
