import UIKit
import Combine
import YandexQuickPay
import YandexPayConfiguration

final class QuickPayViewController: ScrollableViewController {

  private let viewModel = QuickPayViewModel.shared
  private var cancellables = Set<AnyCancellable>()

  // MARK: - SDK widget views

  private lazy var expandableWidgetView: UIView = {
    let v: UIView = YPay.instance.quickPay.createExpandablePaymentMethodsWidget(expandState: .collapsed)
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private lazy var badgeView: UIView = {
    let v: UIView = YPay.instance.quickPay.createActivePaymentMethodBadge()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  // MARK: - UI

  private let badgeContainerView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private let sessionLabel = label("", style: .caption1, color: .secondaryLabel)
  private let copySessionButton: UIButton = {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: "doc.on.doc")
    config.contentInsets = .zero
    return UIButton(configuration: config)
  }()

  private let authStateLabel = label("", style: .subheadline)
  private let securityCheckLabel = label("", style: .caption1, color: .secondaryLabel)

  private let fetchAuthStateButton = yButton("Auth State", size: .small)
  private let fetchSecurityCheckButton = yButton("Security Check", size: .small)

  private let paymentEnabledSwitch = UISwitch()
  private let badgeVisibilitySwitch = UISwitch()

  private let loadingIndicator: UIActivityIndicatorView = {
    let i = UIActivityIndicatorView(style: .medium)
    i.hidesWhenStopped = true
    i.translatesAutoresizingMaskIntoConstraints = false
    return i
  }()

  private let getSessionButton = yButton("Get Session", filled: true, size: .small)
  private let toggleWidgetButton = yButton("Toggle Widget", size: .small)
  private let faqButton = yButton("FAQ", size: .small)
  private let onboardingButton = yButton("Onboarding", size: .small)

  private let errorLabel: UILabel = {
    let l = label("", style: .caption1, color: .systemRed)
    l.numberOfLines = 0
    return l
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    setupActions()
    bindViewModel()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.loadInitialState()
    Task { await viewModel.setupWidgetExpandObserver() }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.cleanup()
  }

  // MARK: - Layout

  private func setupLayout() {
    badgeContainerView.addSubview(badgeView)
    NSLayoutConstraint.activate([
      badgeView.trailingAnchor.constraint(equalTo: badgeContainerView.trailingAnchor),
      badgeView.topAnchor.constraint(equalTo: badgeContainerView.topAnchor),
      badgeView.bottomAnchor.constraint(equalTo: badgeContainerView.bottomAnchor),
    ])

    copySessionButton.translatesAutoresizingMaskIntoConstraints = false
    let sessionRow = hStack([
      label("Session:", style: .subheadline, color: .secondaryLabel),
      sessionLabel,
      copySessionButton
    ], spacing: 4)

    let authStateRow = hStack([
      label("Auth State:", style: .subheadline, color: .secondaryLabel),
      UIView(),
      authStateLabel
    ], spacing: 4)

    let authCard = card(contents: vStack([
      authStateRow,
      securityCheckLabel,
      hStack([fetchAuthStateButton, fetchSecurityCheckButton], spacing: 12)
    ], spacing: 8))

    let controlsCard = card(contents: vStack([
      hStack([label("Quick Payment Enabled"), UIView(), paymentEnabledSwitch]),
      hStack([label("Show Badge"), UIView(), badgeVisibilitySwitch]),
      UIView.separator(),
      loadingIndicator,
      hStack([getSessionButton, toggleWidgetButton], spacing: 12),
      hStack([faqButton, onboardingButton], spacing: 12)
    ], spacing: 12))

    let contentStack = vStack([
      badgeContainerView,
      expandableWidgetView,
      card(contents: sessionRow),
      authCard,
      controlsCard,
      errorLabel
    ], spacing: 16)

    installContent(contentStack)
  }

  // MARK: - Actions

  private func setupActions() {
    paymentEnabledSwitch.addTarget(self, action: #selector(paymentEnabledChanged), for: .valueChanged)
    badgeVisibilitySwitch.addTarget(self, action: #selector(badgeVisibilityChanged), for: .valueChanged)
    copySessionButton.addTarget(self, action: #selector(copySession), for: .touchUpInside)
    fetchAuthStateButton.addTarget(self, action: #selector(fetchAuthState), for: .touchUpInside)
    fetchSecurityCheckButton.addTarget(self, action: #selector(fetchSecurityCheck), for: .touchUpInside)
    getSessionButton.addTarget(self, action: #selector(getSession), for: .touchUpInside)
    toggleWidgetButton.addTarget(self, action: #selector(toggleWidget), for: .touchUpInside)
    faqButton.addTarget(self, action: #selector(showFaq), for: .touchUpInside)
    onboardingButton.addTarget(self, action: #selector(showOnboarding), for: .touchUpInside)
  }

  @objc private func paymentEnabledChanged() { viewModel.toggleQuickPayment(paymentEnabledSwitch.isOn) }
  @objc private func badgeVisibilityChanged() { viewModel.toggleBadgeVisibility(badgeVisibilitySwitch.isOn) }
  @objc private func copySession() { UIPasteboard.general.string = viewModel.sessionId ?? "" }
  @objc private func fetchAuthState() { viewModel.fetchAuthState() }
  @objc private func fetchSecurityCheck() { viewModel.fetchSecurityCheckRequired() }
  @objc private func getSession() { Task { await viewModel.getSession() } }
  @objc private func toggleWidget() { viewModel.toggleWidget() }
  @objc private func showFaq() { Task { await viewModel.showFaqScreen() } }
  @objc private func showOnboarding() { Task { await viewModel.showOnboardingStoriesScreen() } }

  // MARK: - Bindings

  private func bindViewModel() {
    viewModel.$isPaymentEnabled
      .receive(on: DispatchQueue.main)
      .sink { [weak self] enabled in
        self?.paymentEnabledSwitch.setOn(enabled, animated: true)
        self?.badgeVisibilitySwitch.isEnabled = enabled
      }
      .store(in: &cancellables)

    viewModel.$badgeIsVisible
      .receive(on: DispatchQueue.main)
      .sink { [weak self] visible in
        self?.badgeVisibilitySwitch.setOn(visible, animated: true)
        UIView.animate(withDuration: 0.2) {
          self?.badgeContainerView.isHidden = !(self?.viewModel.isPaymentEnabled == true && visible)
        }
      }
      .store(in: &cancellables)

    viewModel.$sessionId
      .receive(on: DispatchQueue.main)
      .sink { [weak self] id in self?.sessionLabel.text = id ?? "-" }
      .store(in: &cancellables)

    viewModel.$currentAuthState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in self?.authStateLabel.text = state }
      .store(in: &cancellables)

    viewModel.$securityCheckResult
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        self?.securityCheckLabel.text = result.map { "Security Check: \($0)" }
        self?.securityCheckLabel.isHidden = result == nil
      }
      .store(in: &cancellables)

    viewModel.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loading in
        if loading { self?.loadingIndicator.startAnimating() }
        else { self?.loadingIndicator.stopAnimating() }
        self?.paymentEnabledSwitch.isEnabled = !loading
        self?.getSessionButton.isEnabled = !loading
      }
      .store(in: &cancellables)

    viewModel.$lastError
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.errorLabel.text = error
        self?.errorLabel.isHidden = error == nil
      }
      .store(in: &cancellables)
  }
}
