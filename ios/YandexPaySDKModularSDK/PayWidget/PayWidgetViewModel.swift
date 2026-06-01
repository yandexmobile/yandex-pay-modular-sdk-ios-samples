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
  @Published var amount: String = "1000"

  private var resultDismissTask: Task<Void, Never>?
  private var stateDismissTask: Task<Void, Never>?

  var payWidgetModel: YPPayWidgetModel {
    guard passAmount, let decimal = Decimal(string: amount) else {
      return YPPayWidgetModel()
    }
    return YPPayWidgetModel(amount: decimal, currency: .rub)
  }

  var widgetIdentity: String {
    "\(passAmount)-\(amount)"
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
    throw PayWidgetError.notSupported
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
      @unknown default: self.showResult("Payment unknown result")
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
  case notSupported
}
