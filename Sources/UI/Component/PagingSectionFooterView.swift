import Combine
import UIKit

public class PagingSectionFooterView: UICollectionReusableView {
    public struct InitialPagingInfo {
        public let count: Int
        public let section: Int
        public let offset: CGFloat

        public init(count: Int, section: Int, offset: CGFloat) {
            self.count = count
            self.section = section
            self.offset = offset
        }
    }

    public struct PagingInfo: Equatable, Hashable {
        let sectionIndex: Int
        let currentPage: Int
        let isFirstIndex: Bool
        let offset: CGFloat

        public init(sectionIndex: Int, currentPage: Int, isFirstIndex: Bool, offset: CGFloat) {
            self.sectionIndex = sectionIndex
            self.currentPage = currentPage
            self.isFirstIndex = isFirstIndex
            self.offset = offset
        }
    }

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isUserInteractionEnabled = false
        control.currentPageIndicatorTintColor = .systemOrange
        control.pageIndicatorTintColor = .systemGray5
        return control
    }()

    private var pagingInfoToken: AnyCancellable?

    private var timer: Timer?

    private var subject: PassthroughSubject<PagingInfo, Never>?, section: Int?

    private var pageControlsubject: PassthroughSubject<PagingInfo, Never>?

    private var initialPagingInfo: InitialPagingInfo? {
        didSet {
            self.pageControl.numberOfPages = self.initialPagingInfo!.count
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }

    public func configure(initialPagingInfo: InitialPagingInfo) {
        self.initialPagingInfo = initialPagingInfo
    }

    public func subscribeTo(
        subject: PassthroughSubject<PagingInfo, Never>,
        pageControlsubject: PassthroughSubject<PagingInfo, Never>,
        for section: Int
    ) {
        self.subject = subject
        self.section = section
        self.pageControlsubject = pageControlsubject

        self.pagingInfoToken = subject
            .filter { $0.sectionIndex == section }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pagingInfo in
                guard let self else { return }

                if self.pageControl.currentPage != pagingInfo.currentPage {
                    self.pageControl.currentPage = pagingInfo.currentPage
                }
            }
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(self.pageControl)

        NSLayoutConstraint.activate([
            self.pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.pageControl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        self.timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            guard let self else { return }

            if self.pageControl.currentPage + 1 == self.pageControl.numberOfPages {
                self.pageControl.currentPage = 0
            } else {
                self.pageControl.currentPage += 1
            }

            self.pageControlValueChanged()
        }
    }

    @objc private func pageControlValueChanged() {
        self.pageControlsubject?
            .send(
                .init(
                    sectionIndex: self.section!,
                    currentPage: self.pageControl.currentPage,
                    isFirstIndex: self.pageControl.currentPage == 0,
                    offset: self.initialPagingInfo!.offset
                )
            )
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        self.pagingInfoToken?.cancel()
        self.pagingInfoToken = nil

        self.timer = nil
    }
}
