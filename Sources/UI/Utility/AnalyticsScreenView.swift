import UIKit
import Utility

public protocol AnalyticsScreenName {
    var screenNameForAnalytics: String { get }
}

public protocol AnalyticsScreenView: UIViewController, AnalyticsScreenName {}

public extension AnalyticsScreenView {
    func sendScreenView() {
        AnalyticsService.shared.sendScreen(screenName: self.screenNameForAnalytics)
    }
}
