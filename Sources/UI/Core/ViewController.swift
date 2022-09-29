import UIKit

open class ViewController: UIViewController, AnalyticsScreenView,
    UIAdaptivePresentationControllerDelegate
{
    open var screenNameForAnalytics: String { "" }

    override open func viewWillAppear(_ animated: Bool) {
        self.sendScreenView()
        super.viewWillAppear(animated)
    }

    open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.sendScreenView()
    }
}
