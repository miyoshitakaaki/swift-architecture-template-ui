import Combine
import UIKit
import Utility

public final class FormTextField: UITextField, UITextFieldDelegate {
    public enum Picker {
        case text(maxCount: Int, allowSpace: Bool),
             date(
                 initial: Date = .init(),
                 minDate: Date? = nil,
                 maxDate: Date? = nil,
                 dateFormat: DateFormat
             ),
             list(initial: String, list: [String]),
             doubleList([String], [String]),
             dateTime(() -> Void)
    }

    override public var text: String? {
        didSet {
            self.textPublisher.send(self.text ?? "")

            switch self.picker {
            case let .date(initial, _, _, dateFormat):
                if let picker = self.inputView as? UIDatePicker {
                    picker.setDate(self.text?.date(from: dateFormat) ?? initial, animated: true)
                }

            case let .list(_, list):
                if
                    let picker = self.inputView as? UIPickerView,
                    let text = self.text,
                    text.isEmpty == false,
                    let index = list.firstIndex(of: text)
                {
                    picker.selectRow(index, inComponent: 0, animated: true)
                }

            default:
                break
            }
        }
    }

    // TODO: should remove this doubleList specfic property
    private var doubleList = ("", "")

    /// テキストフィールド内のinset
    private let inset: CGFloat
    /// 表示ボタンの横幅
    private let optionButtonWidth: CGFloat = 90

    public let textPublisher = CurrentValueSubject<String, Never>("")

    private func calcRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds.insetBy(dx: self.inset, dy: self.inset)

        if self.showOptionButton {
            rect.size = CGSize(
                width: rect.width - (self.optionButtonWidth - self.inset),
                height: rect.height
            )
        }

        return rect
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        self.calcRect(forBounds: bounds)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        self.calcRect(forBounds: bounds)
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        self.calcRect(forBounds: bounds)
    }

    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        .init(
            x: self.showOptionButton
                ? self.frame.width - self.optionButtonWidth
                : self.frame.width - self.inset,
            y: 0,
            width: self.showOptionButton
                ? self.optionButtonWidth
                : self.inset,
            height: bounds.height
        )
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch self.picker {
        case let .dateTime(complete):
            complete()
            return false
        default:
            return true
        }
    }

    private let toolBar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.tintColor = UIColor.rgba(17, 76, 190, 1)
        return toolbar
    }()

    private let underArrowView: UnderArrowView = .init()

    /// optionButtonをTextField.rightViewにサイズ指定して表示するためのコンテナ
    private let optionButtonContainerView: UIView = .init()
    private let optionButton: UIButton = .init(
        style: .init {
            $0.setTitleColor(UIColor.rgba(17, 76, 190, 1), for: .normal)
        },
        title: "表示",
        for: .normal
    )

    private let showOptionButton: Bool
    private var picker: Picker

    public init(
        inset: CGFloat,
        backgroundColor: UIColor = .white,
        placeholder: String,
        placeholderColor: UIColor? = nil,
        picker: Picker = .text(maxCount: .max, allowSpace: true),
        textContentType: UITextContentType? = nil,
        returnKeyType: UIReturnKeyType = .next,
        showOptionButton: Bool = false,
        isSecureTextEntry: Bool = false,
        keyboardType: UIKeyboardType = .default,
        dummyText: String = ""
    ) {
        self.inset = inset
        self.picker = picker
        self.showOptionButton = showOptionButton

        super.init(frame: .zero)

        self.text = dummyText
        self.isSecureTextEntry = isSecureTextEntry
        self.delegate = self
        if let placeholderColor {
            self.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: placeholderColor]
            )
        } else {
            self.placeholder = placeholder
        }
        self.backgroundColor = self.isEnabled ? backgroundColor : UIColor.rgba(238, 238, 238, 1)
        self.textColor = UIColor.rgba(33, 33, 33, 1)
        self.textContentType = textContentType
        self.returnKeyType = returnKeyType
        self.keyboardType = keyboardType

        switch picker {
        case .text:
            break
        case let .date(initial, minDate, maxDate, dateFormat):
            let dateFormat = dateFormat
            let picker = UIDatePicker(style: .init {
                $0.datePickerMode = .date
                $0.preferredDatePickerStyle = .wheels
            })
            picker.date = initial
            picker.minimumDate = minDate
            picker.maximumDate = maxDate
            picker.locale = .init(identifier: "ja_JP")

            var calender = Calendar(identifier: .gregorian)
            calender.locale = .current
            picker.calendar = calender

            picker.addAction(.init(handler: { [weak self] _ in
                self?.text = picker.date.string(to: dateFormat)
            }), for: .valueChanged)

            self.inputView = picker

            addArrowButton()
        case let .list(initial, list):
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self

            if let index = list.firstIndex(of: initial) {
                pickerView.selectRow(index, inComponent: 0, animated: true)
            }
            self.inputView = pickerView

            addArrowButton()

        case .doubleList:
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            self.inputView = pickerView

            addArrowButton()

        case .dateTime:
            addArrowButton()
        }

        self.rightViewMode = .always
        self.rightView = self.optionButton
        self.addTarget(self, action: #selector(self.didValueChanged), for: .editingChanged)
        self.optionButton.addTarget(self, action: #selector(self.secureToggle), for: .touchUpInside)
        self.optionButton.isHidden = !self.showOptionButton

        self.underArrowView.backgroundColor = self.isEnabled ? backgroundColor : UIColor.rgba(
            238,
            238,
            238,
            1
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("no need to implement")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = 8.0
        self.clipsToBounds = true
    }

    @objc func secureToggle() {
        self.isSecureTextEntry.toggle()
        if self.isSecureTextEntry {
            self.optionButton.setTitle("表示", for: .normal)
        } else {
            self.optionButton.setTitle("非表示", for: .normal)
        }
    }

    @objc func didValueChanged(_ sender: UITextField) {
        guard let text = sender.text else { return }

        switch self.picker {
        case .text:
            self.textPublisher.send(text)

        default:
            self.text = text
        }
    }

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        switch self.picker {
        case let .text(maxCount, allowSpace):

            if textField.text!.count >= maxCount, string.isEmpty == false {
                return false
            }

            if allowSpace == false {
                if string == " " || string == "　" {
                    return false
                } else {
                    return true
                }
            }

            return true
        default:
            return true
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.focueNextResponder()
        return true
    }

    func focueNextResponder() {
        let textTag = self.tag + 1
        if let nextResponder = self.superview?.viewWithTag(textTag) as? UIResponder {
            nextResponder.becomeFirstResponder()
        } else {
            self.endEditing(true)
        }
    }

    public func insertListData(_ data: [String]) {
        if case .list = self.picker {
            self.picker = .list(initial: "", list: data)
            if let pickerView = self.inputView as? UIPickerView {
                pickerView.reloadAllComponents()
            }
            self.clear()
        }
    }

    public func clear() {
        self.text = ""
        if let pickerView = self.inputView as? UIPickerView {
            pickerView.selectRow(0, inComponent: 0, animated: false)
        }
    }
}

private extension FormTextField {
    func addArrowButton() {
        addSubviews(
            self.underArrowView,
            constraints: self.underArrowView.trailingAnchor
                .constraint(equalTo: self.trailingAnchor, constant: -21),
            self.underArrowView.topAnchor.constraint(equalTo: self.topAnchor),
            self.underArrowView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.underArrowView.widthAnchor.constraint(equalToConstant: 14)
        )
    }
}

extension FormTextField: Publisher {
    public typealias Output = String
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure,
        String == S.Input
    {
        self.textPublisher.subscribe(subscriber)
    }
}

extension FormTextField: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch self.picker {
        case .list: return 1
        case .doubleList: return 2
        default: return 0
        }
    }

    public func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        if case let .list(_, data) = self.picker {
            return data.count
        } else if case let .doubleList(data1, data2) = self.picker {
            if component == 0 {
                return data1.count
            } else if component == 1 {
                return data2.count
            } else {
                return 0
            }
        } else {
            return 0
        }
    }

    public func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        if case let .list(_, data) = self.picker {
            return data[row]
        } else if case let .doubleList(data1, data2) = self.picker {
            if component == 0 {
                return data1[row]
            } else if component == 1 {
                return data2[row]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    public func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        if case let .list(_, data) = self.picker {
            self.text = data[row]
        } else if case let .doubleList(data1, data2) = self.picker {
            if component == 0 {
                doubleList.0 = data1[row]
            }

            if component == 1 {
                doubleList.1 = data2[row]
            }

            self.text = doubleList.0 + "." + doubleList.1
        }
    }
}

private extension String {
    func removingWhiteSpace() -> String {
        let whiteSpaces: CharacterSet = [" ", "　"]
        return self.trimmingCharacters(in: whiteSpaces)
    }
}
