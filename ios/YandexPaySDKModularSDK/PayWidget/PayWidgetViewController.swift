import UIKit
import Combine
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayConfiguration

final class PayWidgetViewController: ScrollableViewController {

  private let viewModel = PayWidgetViewModel()
  private var cancellables = Set<AnyCancellable>()

  // MARK: - SDK views

  private var widgetContainer = UIView()

  private lazy var payWidgetView: UIView = {
    let v = YPay.instance.payInApp.createPayWidgetUIView(
      model: viewModel.payWidgetModel,
      presentationContextProvider: SamplePresentationContextProvider.shared
    )
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private lazy var redirectButton: YPButton = {
    let button: YPButton = YPay.instance.payWithRedirect.createButton(
      model: .default,
      paymentDataProvider: viewModel,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      delegate: viewModel
    )
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  // MARK: - UI

  private let widgetStateLabel = label("", style: .subheadline, color: .secondaryLabel)

  private let resultLabel: UILabel = {
    let l = UILabel()
    l.font = .preferredFont(forTextStyle: .subheadline)
    l.textAlignment = .center
    l.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    l.layer.cornerRadius = 20
    l.layer.cornerCurve = .continuous
    l.clipsToBounds = true
    l.isHidden = true
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  private let passAmountSwitch = UISwitch()

  private let amountTextField: UITextField = {
    let tf = UITextField()
    tf.text = "1000"
    tf.keyboardType = .decimalPad
    tf.textAlignment = .right
    tf.borderStyle = .roundedRect
    tf.translatesAutoresizingMaskIntoConstraints = false
    return tf
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGreen.withAlphaComponent(0.08)
    setupLayout()
    setupActions()
    bindViewModel()
    YPay.instance.payInApp.setStateDelegate(viewModel)
  }

  // MARK: - Layout

  private func setupLayout() {
    widgetContainer.translatesAutoresizingMaskIntoConstraints = false
    widgetContainer.addSubview(payWidgetView)
    NSLayoutConstraint.activate([
      payWidgetView.topAnchor.constraint(equalTo: widgetContainer.topAnchor),
      payWidgetView.bottomAnchor.constraint(equalTo: widgetContainer.bottomAnchor),
      payWidgetView.leadingAnchor.constraint(equalTo: widgetContainer.leadingAnchor),
      payWidgetView.trailingAnchor.constraint(equalTo: widgetContainer.trailingAnchor),
    ])

    amountTextField.widthAnchor.constraint(equalToConstant: 100).isActive = true
    redirectButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

    let contentStack = vStack([
      widgetContainer,
      redirectButton,
      card(contents: vStack([hStack([label("Widget state"), UIView(), widgetStateLabel])], spacing: 8)),
      card(contents: vStack([
        hStack([label("Send amount to widget"), UIView(), passAmountSwitch]),
        hStack([label("Amount (RUB)"), UIView(), amountTextField])
      ], spacing: 12))
    ], spacing: 16)

    installContent(contentStack)

    view.addSubview(resultLabel)
    NSLayoutConstraint.activate([
      resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
      resultLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
      resultLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
    ])
  }

  // MARK: - Actions

  private func setupActions() {
    passAmountSwitch.addTarget(self, action: #selector(passAmountChanged), for: .valueChanged)
    amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
    addKeyboardDismissGesture()
  }

  @objc private func passAmountChanged() {
    viewModel.passAmount = passAmountSwitch.isOn
    amountTextField.isHidden = !passAmountSwitch.isOn
    refreshWidget()
  }

  @objc private func amountChanged() {
    viewModel.amount = amountTextField.text ?? ""
    refreshWidget()
  }

  private func refreshWidget() {
    payWidgetView.removeFromSuperview()
    let newWidget = YPay.instance.payInApp.createPayWidgetUIView(
      model: viewModel.payWidgetModel,
      presentationContextProvider: SamplePresentationContextProvider.shared
    )
    newWidget.translatesAutoresizingMaskIntoConstraints = false
    widgetContainer.addSubview(newWidget)
    NSLayoutConstraint.activate([
      newWidget.topAnchor.constraint(equalTo: widgetContainer.topAnchor),
      newWidget.bottomAnchor.constraint(equalTo: widgetContainer.bottomAnchor),
      newWidget.leadingAnchor.constraint(equalTo: widgetContainer.leadingAnchor),
      newWidget.trailingAnchor.constraint(equalTo: widgetContainer.trailingAnchor),
    ])
  }

  // MARK: - Bindings

  private func bindViewModel() {
    passAmountSwitch.setOn(viewModel.passAmount, animated: false)
    amountTextField.isHidden = !viewModel.passAmount

    viewModel.$widgetState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in self?.widgetStateLabel.text = state }
      .store(in: &cancellables)

    viewModel.$paymentResult
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self else { return }
        if let result {
          resultLabel.text = "  \(result)  "
          resultLabel.isHidden = false
          UIView.animate(withDuration: 0.3) { self.resultLabel.alpha = 1 }
        } else {
          UIView.animate(withDuration: 0.3) { self.resultLabel.alpha = 0 } completion: { _ in
            self.resultLabel.isHidden = true
          }
        }
      }
      .store(in: &cancellables)
  }
}
