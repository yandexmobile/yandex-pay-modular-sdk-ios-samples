import UIKit
import Combine
import YandexPayWithRedirect
import YandexPayConfiguration

final class RedirectsViewController: ScrollableViewController {

  private let orderSettings: OrderSettings
  private let urlProvider: PaymentURLProvider
  private let viewModel: RedirectsViewModel
  private var cancellables = Set<AnyCancellable>()

  init(orderSettings: OrderSettings, urlProvider: PaymentURLProvider) {
    self.orderSettings = orderSettings
    self.urlProvider = urlProvider
    self.viewModel = RedirectsViewModel(urlProvider: urlProvider)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - SDK button (UIView overload)

  private lazy var payButton: YPButton = {
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

  private let openFormButton = yButton("Open Pay Form")
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

  private let resultLabel = label("", style: .subheadline, color: .secondaryLabel)

  private let resultCard: UIView = {
    let v = UIView()
    v.backgroundColor = UIColor.secondarySystemGroupedBackground
    v.layer.cornerRadius = 12
    v.layer.cornerCurve = .continuous
    v.translatesAutoresizingMaskIntoConstraints = false
    v.isHidden = true
    return v
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    setupActions()
    bindViewModel()
  }

  // MARK: - Layout

  private func setupLayout() {
    payButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    activityIndicator.hidesWhenStopped = true
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false

    resultLabel.translatesAutoresizingMaskIntoConstraints = false
    resultCard.addSubview(resultLabel)
    NSLayoutConstraint.activate([
      resultLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 12),
      resultLabel.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -12),
      resultLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
      resultLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
    ])

    let contentStack = vStack([
      sectionCard(
        header: "Actions",
        contents: vStack([payButton, openFormButton, activityIndicator, errorLabel], spacing: 12)
      ),
      resultCard
    ], spacing: 16)

    installContent(contentStack)
  }

  // MARK: - Actions

  private func setupActions() {
    openFormButton.addTarget(self, action: #selector(openForm), for: .touchUpInside)
  }

  @objc private func openForm() {
    Task { await viewModel.openPayForm() }
  }

  // MARK: - Bindings

  private func bindViewModel() {
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

    viewModel.$paymentResult
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self else { return }
        if case .payment(let outcome) = result {
          resultLabel.text = outcome.displayString
          resultLabel.textColor = outcome.isSucceeded ? .systemGreen : .secondaryLabel
          resultCard.isHidden = false
        } else {
          resultCard.isHidden = true
        }
      }
      .store(in: &cancellables)
  }
}
