import Combine
import UIKit

extension ViewStyle where T: UIButton {
    static var accentBlue: ViewStyle<T> {
        ViewStyle<T> {
            $0.setTitleColor(UIConfig.accentBlue, for: .normal)
        }
    }
}

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

public final class FormTextField: UITextField, UITextFieldDelegate {
    public enum DatePicker {
        case birthday, normal
    }

    public enum Picker {
        case text, date(DatePicker), list([String]), doubleList([String], [String]),
             dateTime(() -> Void)
    }

    override public var text: String? {
        didSet {
            self.textPublisher.send(self.text ?? "")
        }
    }

    // TODO: should remove this doubleList specfic property
    private var doubleList = ("", "")

    /// テキストフィールド内のinset
    private let inset: CGFloat = 16
    /// 表示ボタンの横幅
    private let showButtonWidth: CGFloat = 90
    /// 表示ボタンの高さ
    private let textFieldHeight: CGFloat = 50

    public let textPublisher = CurrentValueSubject<String, Never>("")

    private func calcRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds.insetBy(dx: self.inset, dy: self.inset)
        if (!self.showOptionButton) {
            return rect
        } else {
            rect.size = CGSize(width: rect.width - (showButtonWidth - inset),
                               height: rect.height)
            return rect
        }
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        calcRect(forBounds: bounds)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        calcRect(forBounds: bounds)
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        calcRect(forBounds: bounds)
    }


    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        if (!self.showOptionButton) {
            return CGRect(x: self.frame.width - self.inset, y: 0,
                          width: self.inset, height: self.textFieldHeight)
        } else {
            return CGRect(x: self.frame.width - self.showButtonWidth, y: 0,
                          width: self.showButtonWidth, height: self.textFieldHeight)
        }
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

    override public var isEnabled: Bool {
        didSet {
            self.backgroundColor = self.isEnabled ? .white : UIConfig.lightGray_200
            self.underArrowView.backgroundColor = self.isEnabled ? .white : UIConfig.lightGray_200
        }
    }

    private let toolBar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.tintColor = UIConfig.accentBlue
        return toolbar
    }()

    private let underArrowView: UnderArrowView = .init()

    /// optionButtonをTextField.rightViewにサイズ指定して表示するためのコンテナ
    private let optionButtonContainerView: UIView = .init()
    private let optionButton: UIButton = .init(
        style: .accentBlue,
        title: "表示",
        for: .normal
    )

    private var showOptionButton: Bool = false
    private var picker: Picker

    public init(
        placeholder: String,
        placeholderColor: UIColor? = nil,
        picker: Picker = .text,
        textContentType: UITextContentType? = nil,
        returnKeyType: UIReturnKeyType = .next,
        showOptionButton: Bool = false,
        isSecureTextEntry: Bool = false,
        isNumberKeyBoard: Bool = false,
        dummyText: String = ""
    ) {
        self.picker = picker

        super.init(frame: .zero)
        
        self.text = dummyText
        self.showOptionButton = showOptionButton
        self.isSecureTextEntry = isSecureTextEntry
        self.delegate = self
        if let placeholderColor = placeholderColor {
            self.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: placeholderColor]
            )
        } else {
            self.placeholder = placeholder
        }
        self.backgroundColor = .white
        self.textColor = UIConfig.darkGray_900
        self.textContentType = textContentType
        self.returnKeyType = returnKeyType

        if isNumberKeyBoard {
            self.keyboardType = .numberPad
        }

        switch picker {
        case .text:
            break
        case let .date(type):
            let picker = UIDatePicker(style: .someStyle)
            if type == .birthday {
                let befor55years = Date().year - 55
                picker.date = "\(befor55years)/01/01".date(from: .yyyyMMddSlash) ?? Date()
            }
            picker.addTarget(
                self,
                action: #selector(self.didDatePickerSelected(sender:)),
                for: .valueChanged
            )
            self.inputView = picker

            addArrowButton()
        case .list, .doubleList:
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            self.inputView = pickerView

            addArrowButton()

        case .dateTime:
            addArrowButton()
        }

        /*
         テキスト入力エリア左右の余白
         rightViewを使用して余白を設ける
         セキュアのときはボタン用のスペースを算出し下記funcで返す必要がある
         `rightViewRect(forBounds bounds: CGRect) -> CGRect`
         */
        self.rightViewMode = .always

        self.optionButtonContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.optionButtonContainerView.backgroundColor = .clear
        self.rightView = self.optionButtonContainerView
        if (!self.showOptionButton) {
            // 非セキュア
            optionButtonContainerView.widthAnchor.constraint(equalToConstant: self.inset).isActive = true
            optionButtonContainerView.heightAnchor.constraint(equalToConstant: self.textFieldHeight).isActive = true
        } else {
            // セキュア
            // UITextField.rightViewに直接UIButtonをaddSubviewするとリサイズされてしまうためUIViewでwrapする
            self.optionButton.translatesAutoresizingMaskIntoConstraints = false
            self.optionButtonContainerView.addSubviews(
                self.optionButton,
                constraints:
                self.optionButton.topAnchor.constraint(equalTo: self.optionButtonContainerView.topAnchor, constant: 0),
                self.optionButton.leadingAnchor.constraint(equalTo: self.optionButtonContainerView.leadingAnchor, constant: 0),
                self.optionButton.trailingAnchor.constraint(equalTo: self.optionButtonContainerView.trailingAnchor, constant: 0),
                self.optionButton.bottomAnchor.constraint(equalTo: self.optionButtonContainerView.bottomAnchor, constant: 0),
                self.optionButton.widthAnchor.constraint(equalToConstant: self.showButtonWidth),
                self.optionButton.heightAnchor.constraint(equalToConstant: self.textFieldHeight)
            )
            optionButton.titleLabel?.textAlignment = .center
            self.addTarget(self, action: #selector(self.didValueChanged), for: .editingChanged)
            self.optionButton.addTarget(self, action: #selector(self.secureToggle), for: .touchUpInside)
        }
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
        self.textPublisher.send(sender.text ?? "")
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

    @objc func didDatePickerSelected(sender: UIDatePicker) {
        self.text = sender.date.dateJp
    }

    public func insertListData(_ data: [String]) {
        if case .list = self.picker {
            self.picker = .list(data)
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
        if case let .list(data) = self.picker {
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
        if case let .list(data) = self.picker {
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
        if case let .list(data) = self.picker {
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
