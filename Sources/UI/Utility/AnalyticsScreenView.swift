import UIKit
import Utility

public protocol AnalyticsScreenName {
    var screenNameForAnalytics: String { get }
    var screenEventForAnalytics: AnalyticsEvent? { get }
}

public extension AnalyticsScreenName {
    var screenEventForAnalytics: AnalyticsEvent? { nil }
}

public protocol AnalyticsScreenView: UIViewController, AnalyticsScreenName {}

public extension AnalyticsScreenView {
    func sendScreenView() {
        AnalyticsService.shared.sendScreen(screenName: self.screenNameForAnalytics)
        if let screenEventForAnalytics = self.screenEventForAnalytics {
            AnalyticsService.shared.sendEvent(screenEventForAnalytics)
        }
    }
}
