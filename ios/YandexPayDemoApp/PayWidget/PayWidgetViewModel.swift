import SwiftUI
import Combine
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayConfiguration

@MainActor
final class PayWidgetViewModel: ObservableObject {
  @Published var widgetState: String = "-"
  @Published var paymentResult: String?
  @Published var passAmount: Bool = true

  let urlProvider: PaymentURLProvider
  private let orderSettings: OrderSettings
  private var resultDismissTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  init(orderSettings: OrderSettings, urlProvider: PaymentURLProvider) {
    self.orderSettings = orderSettings
    self.urlProvider = urlProvider
    orderSettings.$order
      .sink { [weak self] _ in self?.objectWillChange.send() }
      .store(in: &cancellables)
  }

  var payWidgetModel: YPPayWidgetModel {
    guard passAmount else { return YPPayWidgetModel() }
    return YPPayWidgetModel(
      amount: orderSettings.order.resolvedTotalDecimal(),
      currency: orderSettings.order.resolvedCurrency()
    )
  }

  var widgetIdentity: String {
    "\(passAmount)-\(orderSettings.order.resolvedTotalString())-\(orderSettings.order.currencyCode)"
  }

  private func showResult(_ message: String) {
    paymentResult = message
    resultDismissTask?.cancel()
    resultDismissTask = Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard !Task.isCancelled else { return }
      self?.paymentResult = nil
    }
  }
}

// MARK: - YPButtonPaymentDataProviding

extension PayWidgetViewModel: YPButtonPaymentDataProviding {
  func paymentUrl(for yandexPayButton: any YPButtonProtocol) async throws -> String {
    guard let url = await urlProvider.resolvePaymentURL() else {
      throw PayWidgetError.noPaymentURL
    }
    return url.absoluteString
  }
}

// MARK: - YPButtonDelegate

extension PayWidgetViewModel: YPButtonDelegate {
  nonisolated func yandexPayButton(
    _ button: any YPButtonProtocol,
    didCompletePaymentWithResult result: YPPaymentResult,
    data: YPPaymentData
  ) {
    Task { @MainActor in
      switch result {
      case .succeeded: self.showResult("Payment succeeded")
      case .cancelled: self.showResult("Payment cancelled")
      case .failed: self.showResult("Payment failed")
      @unknown default: self.showResult("Unknown result")
      }
    }
  }
}

// MARK: - YPInAppDelegate

extension PayWidgetViewModel: YPInAppDelegate {
  nonisolated func yandexPayInApp(didChangeState state: YPInAppState) {
    Task { @MainActor in
      switch state {
      case .loading: self.widgetState = "loading"
      case .enabled: self.widgetState = "enabled"
      case .disabled(.disabledByConfig): self.widgetState = "disabled (config)"
      case .disabled(.disabledByMerchant): self.widgetState = "disabled (merchant)"
      case .disabled(.unknown): self.widgetState = "disabled (unknown)"
      }
    }
  }
}

enum PayWidgetError: Error {
  case noPaymentURL
}
