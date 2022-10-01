import UIKit
import Utility

open class ViewController: UIViewController, AnalyticsScreenView,
    UIAdaptivePresentationControllerDelegate
{
    open var screenNameForAnalytics: String { "" }

    open var screenEventForAnalytics: [AnalyticsEvent] { [] }

    override open func viewWillAppear(_ animated: Bool) {
        self.sendScreenView()
        super.viewWillAppear(animated)
    }

    open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.sendScreenView()
    }
}
