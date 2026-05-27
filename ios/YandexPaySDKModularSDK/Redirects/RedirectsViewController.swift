import UIKit
import Combine
import YandexPayWithRedirect
import YandexPayConfiguration

final class RedirectsViewController: ScrollableViewController {

  private let viewModel = RedirectsViewModel()
  private var cancellables = Set<AnyCancellable>()

  // MARK: - SDK button (UIView overload)

  private lazy var payButton: YPButton = {
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

  private let urlTextField: UITextField = {
    let tf = UITextField()
    tf.placeholder = "https://..."
    tf.keyboardType = .URL
    tf.autocapitalizationType = .none
    tf.autocorrectionType = .no
    tf.borderStyle = .roundedRect
    tf.clearButtonMode = .whileEditing
    tf.translatesAutoresizingMaskIntoConstraints = false
    return tf
  }()

  private let openFormButton = yButton("Open Pay Form")

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
        header: "Payment URL",
        footer: "Enter a Yandex Pay payment URL to use with the pay button or form.",
        contents: urlTextField
      ),
      sectionCard(header: "Actions", contents: vStack([payButton, openFormButton], spacing: 12)),
      resultCard
    ], spacing: 16)

    installContent(contentStack)
  }

  // MARK: - Actions

  private func setupActions() {
    openFormButton.addTarget(self, action: #selector(openForm), for: .touchUpInside)
    urlTextField.addTarget(self, action: #selector(urlChanged), for: .editingChanged)
    addKeyboardDismissGesture()
  }

  @objc private func openForm() { viewModel.openPayForm() }

  @objc private func urlChanged() { viewModel.paymentURL = urlTextField.text ?? "" }

  // MARK: - Bindings

  private func bindViewModel() {
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
