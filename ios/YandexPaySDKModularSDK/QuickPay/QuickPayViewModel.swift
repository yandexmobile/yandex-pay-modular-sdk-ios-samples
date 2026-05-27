import Combine
import Foundation
import YandexQuickPay
import YandexPayConfiguration

@MainActor
final class QuickPayViewModel: ObservableObject, YQuickPaymentStateListener {

  static let shared = QuickPayViewModel()

  @Published var isPaymentEnabled: Bool = false
  @Published var isLoading: Bool = false
  @Published var lastError: String?

  @Published var sessionId: String?
  @Published var badgeIsVisible: Bool = false
  @Published var isWidgetExpanded: Bool = false

  @Published var currentAuthState: String = "-"
  @Published var securityCheckResult: String?

  private var widgetExpandObserverID: UUID?

  private init() {}

  private var quickPay: YQuickPay {
    YPay.instance.quickPay
  }

  func loadInitialState() {
    quickPay.addAuthStateObserver(self)
    guard !isLoading else { return }
    isLoading = true
    Task { @MainActor in
      do {
        let previousState = isPaymentEnabled
        isPaymentEnabled = try await quickPay.isQuickPaymentEnabled()
        badgeIsVisible = isPaymentEnabled
        if !previousState, isPaymentEnabled {
          await getSession()
        }
        lastError = nil
      } catch {
        lastError = String(describing: error)
      }
      isLoading = false
    }
  }

  func cleanup() {
    quickPay.removeAuthStateObserver(self)
    Task { await removeWidgetExpandObserver() }
  }

  func toggleQuickPayment(_ enabled: Bool) {
    guard !isLoading else { return }
    isLoading = true
    Task { @MainActor in
      do {
        if enabled {
          try await quickPay.enableQuickPayment()
        } else {
          try await quickPay.disableQuickPayment()
        }
        isPaymentEnabled = enabled
        if !enabled {
          badgeIsVisible = false
          sessionId = nil
        }
        lastError = nil
      } catch {
        lastError = String(describing: error)
      }
      isLoading = false
    }
  }

  func getSession() async {
    do {
      sessionId = try await quickPay.getPaymentSessionId()
      lastError = nil
    } catch {
      lastError = String(describing: error)
    }
  }

  func toggleBadgeVisibility(_ visible: Bool) {
    badgeIsVisible = visible
    if visible {
      quickPay.enableActivePaymentMethodBadge()
    } else {
      quickPay.disableActivePaymentMethodBadge()
    }
  }

  func toggleWidget() {
    isWidgetExpanded.toggle()
    quickPay.setWidgetExpanded(isWidgetExpanded ? .expanded : .collapsed)
  }

  func setupWidgetExpandObserver() async {
    guard widgetExpandObserverID == nil else { return }
    widgetExpandObserverID = await quickPay.addWidgetExpandChangeObserver { [weak self] state in
      Task { @MainActor in
        self?.isWidgetExpanded = state == .expanded
      }
    }
  }

  func removeWidgetExpandObserver() async {
    guard let id = widgetExpandObserverID else { return }
    await quickPay.removeWidgetExpandChangeObserver(forId: id)
    widgetExpandObserverID = nil
  }

  func showFaqScreen() async {
    await quickPay.showFaqScreen()
  }

  func showOnboardingStoriesScreen() async {
    await quickPay.showOnboardingStoriesScreen()
  }

  func fetchAuthState() {
    Task { @MainActor in
      currentAuthState = await quickPay.getAuthState().displayName
    }
  }

  func fetchSecurityCheckRequired() {
    Task { @MainActor in
      do {
        let required = try await quickPay.isSecurityCheckRequired()
        securityCheckResult = required ? "Required" : "Not required"
        lastError = nil
      } catch {
        lastError = String(describing: error)
      }
    }
  }

  nonisolated func onPaymentEnabledStateChanged(isEnabled: Bool) {
    Task { @MainActor in
      self.isPaymentEnabled = isEnabled
      self.badgeIsVisible = isEnabled
    }
  }

  nonisolated func onSessionExpired() {
    Task { @MainActor in
      await self.getSession()
    }
  }

  nonisolated func onPaymentResult(quickpayResult: YQuickPayResult) {
    Task { @MainActor in
      self.sessionId = nil
      await self.getSession()
    }
  }
}

extension QuickPayViewModel: YQuickPayAuthStateObserver {
  nonisolated func onAuthStateChanged(_ state: YQuickPayAuthState) {
    Task { @MainActor in
      self.currentAuthState = state.displayName
    }
  }
}

private extension YQuickPayAuthState {
  var displayName: String {
    switch self {
    case .notAuthorized: "Not authorized"
    case .authorizationInProgress: "Authorization in progress"
    case .accountAuthorizedNotActivated: "Account authorized (not activated)"
    case .accountAuthorized: "Account authorized"
    case .securityCheckInProgress: "Security check in progress"
    case .securityCheckRequired: "Security check required"
    case .securityCheckCompleted: "Security check completed"
    case .securityCheckFailed(let reason):
      switch reason {
      case .userCancelled: "Security check failed: user cancelled"
      case .biometryNotAvailable: "Security check failed: biometry not available"
      case .notInteractive: "Security check failed: not interactive"
      case .unknownError: "Security check failed: unknown error"
      }
    }
  }
}
