import UIKit

extension ViewStyle where T: UIDatePicker {
    static var someStyle: ViewStyle<T> {
        ViewStyle<T> {
            $0.date = Date()
            $0.datePickerMode = .date
            if #available(iOS 13.4, *) {
                $0.preferredDatePickerStyle = .wheels
            }
        }
    }
}
