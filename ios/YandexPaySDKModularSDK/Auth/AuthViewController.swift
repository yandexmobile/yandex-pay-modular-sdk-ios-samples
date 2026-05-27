import UIKit
import Combine
import YandexPayAuth

final class AuthViewController: UIViewController {

  private let viewModel = AuthViewModel()
  private var cancellables = Set<AnyCancellable>()

  // MARK: - UI

  private let strategyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Default", "Web Only", "Primary Only"])
    control.selectedSegmentIndex = 0
    control.translatesAutoresizingMaskIntoConstraints = false
    return control
  }()

  private let loginButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Login"
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private let logoutButton: UIButton = {
    var config = UIButton.Configuration.bordered()
    config.title = "Logout"
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.translatesAutoresizingMaskIntoConstraints = false
    return indicator
  }()

  private let statusLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .caption1)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let errorLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .caption1)
    label.textColor = .systemRed
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
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
    let card = UIView()
    card.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
    card.layer.cornerRadius = 20
    card.layer.cornerCurve = .continuous
    card.translatesAutoresizingMaskIntoConstraints = false

    let buttonsStack = UIStackView(arrangedSubviews: [loginButton, logoutButton])
    buttonsStack.axis = .horizontal
    buttonsStack.spacing = 12
    buttonsStack.distribution = .fillEqually
    buttonsStack.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [
      strategyControl,
      buttonsStack,
      activityIndicator,
      statusLabel,
      errorLabel
    ])
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false

    card.addSubview(stack)
    view.addSubview(card)

    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
    ])
  }

  // MARK: - Actions

  private func setupActions() {
    loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    strategyControl.addTarget(self, action: #selector(strategyChanged), for: .valueChanged)
  }

  @objc private func loginTapped() {
    viewModel.login()
  }

  @objc private func logoutTapped() {
    viewModel.logout()
  }

  @objc private func strategyChanged() {
    let strategies: [YPAuthorizationStrategy] = [.default, .webOnly, .primaryOnly]
    viewModel.selectedStrategy = strategies[strategyControl.selectedSegmentIndex]
  }

  // MARK: - Bindings

  private func bindViewModel() {
    viewModel.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loading in
        if loading {
          self?.activityIndicator.startAnimating()
        } else {
          self?.activityIndicator.stopAnimating()
        }
        self?.loginButton.isEnabled = !loading && !(self?.viewModel.isLoggedIn ?? false)
        self?.logoutButton.isEnabled = !loading && (self?.viewModel.isLoggedIn ?? false)
        self?.strategyControl.isEnabled = !loading && !(self?.viewModel.isLoggedIn ?? false)
      }
      .store(in: &cancellables)

    viewModel.$isLoggedIn
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loggedIn in
        guard let self else { return }
        statusLabel.text = loggedIn ? "Logged in" : "Not logged in"
        statusLabel.textColor = loggedIn ? .systemGreen : .secondaryLabel
        loginButton.isEnabled = !loggedIn && !viewModel.isLoading
        logoutButton.isEnabled = loggedIn && !viewModel.isLoading
        strategyControl.isEnabled = !loggedIn && !viewModel.isLoading
      }
      .store(in: &cancellables)

    viewModel.$errorMessage
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.errorLabel.text = error
        self?.errorLabel.isHidden = error == nil
      }
      .store(in: &cancellables)
  }
}
