import UIKit
import Utility

public protocol AnalyticsScreenName {
    var screenNameForAnalytics: [AnalyticsScreen] { get }
    var screenEventForAnalytics: [AnalyticsEvent] { get }
}

public extension AnalyticsScreenName {
    var screenNameForAnalytics: [AnalyticsScreen] { [] }
    var screenEventForAnalytics: [AnalyticsEvent] { [] }
}

public protocol AnalyticsScreenView: UIViewController, AnalyticsScreenName {}

public extension AnalyticsScreenView {
    func sendScreenView() {
        screenNameForAnalytics.forEach(AnalyticsService.shared.sendScreen)
        screenEventForAnalytics.forEach(AnalyticsService.shared.sendEvent)
    }
}
