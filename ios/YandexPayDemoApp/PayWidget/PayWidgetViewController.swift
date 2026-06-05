import UIKit
import Combine
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayConfiguration

final class PayWidgetViewController: ScrollableViewController {

  private let orderSettings: OrderSettings
  private let urlProvider: PaymentURLProvider
  private let viewModel: PayWidgetViewModel
  private var cancellables = Set<AnyCancellable>()

  init(orderSettings: OrderSettings, urlProvider: PaymentURLProvider) {
    self.orderSettings = orderSettings
    self.urlProvider = urlProvider
    self.viewModel = PayWidgetViewModel(orderSettings: orderSettings, urlProvider: urlProvider)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - SDK views

  private var widgetContainer = UIView()

  private lazy var redirectButton: YPButton = {
    let button: YPButton = YPay.instance.payWithRedirect.createButton(
      model: YPButtonModel(
        amount: orderSettings.order.resolvedTotalDecimal(),
        currency: orderSettings.order.resolvedCurrency()
      ),
      paymentDataProvider: viewModel,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      delegate: viewModel
    )
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  // MARK: - UI

  private let widgetStateLabel = label("", style: .subheadline, color: .secondaryLabel)
  private let orderTotalLabel = label("", style: .subheadline, color: .secondaryLabel)
  private let passAmountSwitch = UISwitch()
  private let activityIndicator = UIActivityIndicatorView(style: .medium)

  private let errorLabel: UILabel = {
    let l = UILabel()
    l.font = .preferredFont(forTextStyle: .footnote)
    l.textColor = .systemRed
    l.numberOfLines = 0
    l.isHidden = true
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

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
    refreshWidget()

    redirectButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    activityIndicator.hidesWhenStopped = true
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false

    let contentStack = vStack([
      widgetContainer,
      card(contents: vStack([
        hStack([label("Widget state"), UIView(), widgetStateLabel])
      ], spacing: 8)),
      card(contents: vStack([
        hStack([label("Order total"), UIView(), orderTotalLabel]),
        hStack([label("Send amount to widget"), UIView(), passAmountSwitch])
      ], spacing: 12)),
      sectionCard(
        header: "Actions",
        contents: vStack([redirectButton, activityIndicator, errorLabel], spacing: 8)
      )
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
  }

  @objc private func passAmountChanged() {
    viewModel.passAmount = passAmountSwitch.isOn
    refreshWidget()
  }

  private func refreshWidget() {
    widgetContainer.subviews.forEach { $0.removeFromSuperview() }
    let widget = YPay.instance.payInApp.createPayWidgetUIView(
      model: viewModel.payWidgetModel,
      presentationContextProvider: SamplePresentationContextProvider.shared
    )
    widget.translatesAutoresizingMaskIntoConstraints = false
    widgetContainer.addSubview(widget)
    NSLayoutConstraint.activate([
      widget.topAnchor.constraint(equalTo: widgetContainer.topAnchor),
      widget.bottomAnchor.constraint(equalTo: widgetContainer.bottomAnchor),
      widget.leadingAnchor.constraint(equalTo: widgetContainer.leadingAnchor),
      widget.trailingAnchor.constraint(equalTo: widgetContainer.trailingAnchor),
    ])
  }

  // MARK: - Bindings

  private func bindViewModel() {
    passAmountSwitch.setOn(viewModel.passAmount, animated: false)
    orderTotalLabel.text = "\(orderSettings.order.resolvedTotalString()) \(orderSettings.order.currencyCode)"

    urlProvider.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loading in
        loading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
      }
      .store(in: &cancellables)

    urlProvider.$errorMessage
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.errorLabel.text = error
        self?.errorLabel.isHidden = error == nil
      }
      .store(in: &cancellables)

    orderSettings.$order
      .receive(on: DispatchQueue.main)
      .sink { [weak self] order in
        self?.orderTotalLabel.text = "\(order.resolvedTotalString()) \(order.currencyCode)"
      }
      .store(in: &cancellables)

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
