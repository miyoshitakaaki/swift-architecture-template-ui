import UIKit

class ImagePresentedAnimator<
    Presenting: UIViewController,
    Presented: ImageDestinationTransitionType
>: NSObject, UIViewControllerAnimatedTransitioning {
    weak var targetView: UIImageView?

    private let duration: TimeInterval = 1

    init(targetView: UIImageView) {
        self.targetView = targetView
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
        -> TimeInterval
    {
        self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presented = transitionContext
            .viewController(forKey: UITransitionContextViewControllerKey.to)

        let presenting = transitionContext
            .viewController(forKey: UITransitionContextViewControllerKey.from)

        guard
            let presenting = presenting as? Presenting,
            let presented = presented as? Presented,
            let targetView
        else {
            transitionContext.cancelInteractiveTransition()
            return
        }

        let containerView = transitionContext.containerView

        presented.view.frame = transitionContext.finalFrame(for: presented)
        presented.view.layoutIfNeeded()
        presented.view.alpha = 0

        containerView.addSubview(presented.view)

        let animationView = UIView(frame: presenting.view.frame)
        animationView.backgroundColor = presented.view.backgroundColor?.withAlphaComponent(0)

        let frame = targetView.superview!.convert(
            targetView.frame,
            to: animationView
        )

        let imageView = UIImageView(frame: frame)
        imageView.image = targetView.image
        imageView.contentMode = targetView.contentMode
        animationView.addSubview(imageView)
        containerView.addSubview(animationView)

        let animation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            if presented.imageView.frame.size.width < presented.imageView.frame.size.height {
                let width = presented.imageView.frame.size.width
                let height: CGFloat = frame.size.height / frame.size.width * width

                imageView.frame.size = .init(
                    width: width,
                    height: height
                )
            } else {
                let height = presented.imageView.frame.size.height
                let width = frame.size.width / frame.size.height * height

                imageView.frame.size = .init(
                    width: width,
                    height: height
                )
            }

            imageView.center = presented.imageView.center

            animationView.backgroundColor = presented.view.backgroundColor?.withAlphaComponent(1)
        }

        animation.addCompletion { _ in
            presented.view.alpha = 1
            animationView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
        animation.startAnimation()
    }
}
