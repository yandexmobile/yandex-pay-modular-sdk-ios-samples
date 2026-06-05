import Foundation
import SwiftUI
import Combine

import YandexPayWithRedirect
import YandexPayConfiguration

@MainActor
final class RedirectsViewModel: ObservableObject {
  @Published var paymentResult: PaymentResult?
  @Published var retainedForm: YPForm?

  let urlProvider: PaymentURLProvider

  init(urlProvider: PaymentURLProvider) {
    self.urlProvider = urlProvider
  }

  func makePayButtonView(orderSettings: OrderSettings) -> some View {
    let button: any View = YPay.instance.payWithRedirect.createButton(
      model: YPButtonModel(
        amount: orderSettings.order.resolvedTotalDecimal(),
        currency: orderSettings.order.resolvedCurrency(),
        preferredPaymentMethods: orderSettings.order.availablePaymentMethods
          .compactMap { YPAvailablePaymentMethod(rawValue: $0.lowercased()) }
      ),
      paymentDataProvider: self,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      delegate: self
    )
    return AnyView(button)
  }

  func openPayForm() async {
    guard let url = await urlProvider.resolvePaymentURL() else { return }
    let form = YPay.instance.payWithRedirect.createYandexPayForm(paymentURL: url, delegate: self)
    retainedForm = form
    form.present(anchor: .keyWindow, animated: true, completion: nil)
  }
}

// MARK: - YPButtonPaymentDataProviding

extension RedirectsViewModel: YPButtonPaymentDataProviding {
  func paymentUrl(for yandexPayButton: any YPButtonProtocol) async throws -> String {
    guard let url = await urlProvider.resolvePaymentURL() else {
      throw RedirectsError.noPaymentURL
    }
    return url.absoluteString
  }
}

// MARK: - YPButtonDelegate

extension RedirectsViewModel: YPButtonDelegate {
  nonisolated func yandexPayButton(
    _ button: any YPButtonProtocol,
    didCompletePaymentWithResult result: YPPaymentResult,
    data: YPPaymentData
  ) {
    Task { @MainActor in
      self.paymentResult = .payment(YPPaymentOutcome(result))
    }
  }
}

// MARK: - YPFormDelegate

extension RedirectsViewModel: YPFormDelegate {
  nonisolated func yandexPayForm(
    _ payForm: YPForm,
    data: YPPaymentData,
    didCompletePaymentWithResult result: YPPaymentResult
  ) {
    Task { @MainActor in
      self.retainedForm = nil
      self.paymentResult = .payment(YPPaymentOutcome(result))
    }
  }
}

// MARK: - Supporting Types

enum RedirectsError: Error {
  case noPaymentURL
}

enum PaymentResult {
  case payment(YPPaymentOutcome)
}

enum YPPaymentOutcome {
  case succeeded, cancelled, failed

  init(_ result: YPPaymentResult) {
    switch result {
    case .succeeded: self = .succeeded
    case .cancelled: self = .cancelled
    case .failed: self = .failed
    @unknown default: self = .failed
    }
  }

  var displayString: String {
    switch self {
    case .succeeded: "Payment succeeded"
    case .cancelled: "Payment cancelled"
    case .failed: "Payment failed"
    }
  }

  var isSucceeded: Bool { self == .succeeded }
}
