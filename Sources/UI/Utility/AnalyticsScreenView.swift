import UIKit
import Utility

public protocol AnalyticsScreenName {
    var screenNameForAnalytics: String { get }
    var screenEventForAnalytics: [AnalyticsEvent] { get }
}

public extension AnalyticsScreenName {
    var screenEventForAnalytics: [AnalyticsEvent] { [] }
}

public protocol AnalyticsScreenView: UIViewController, AnalyticsScreenName {}

public extension AnalyticsScreenView {
    func sendScreenView() {
        AnalyticsService.shared.sendScreen(screenName: self.screenNameForAnalytics)
        screenEventForAnalytics.forEach(AnalyticsService.shared.sendEvent)
    }
}
