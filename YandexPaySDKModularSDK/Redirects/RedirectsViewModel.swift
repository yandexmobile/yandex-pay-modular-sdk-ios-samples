import Foundation
import SwiftUI
import YandexPayWithRedirect
import YandexPayConfiguration
import Combine

@MainActor
final class RedirectsViewModel: ObservableObject {
  @Published var paymentURL: String = ""
  @Published var paymentResult: PaymentResult?
  @Published var retainedForm: YPForm?

  func makePayButtonView() -> some View {
    let button: any View = YPay.instance.payWithRedirect.createButton(
      model: .default,
      paymentDataProvider: self,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      delegate: self
    )
    return AnyView(button)
  }

  func openPayForm() {
    guard let url = URL(string: paymentURL), !paymentURL.isEmpty else { return }
    let form = YPay.instance.payWithRedirect.createYandexPayForm(paymentURL: url, delegate: self)
    retainedForm = form
    form.present(anchor: .keyWindow, animated: true, completion: nil)
  }
}

// MARK: - YPButtonPaymentDataProviding

extension RedirectsViewModel: YPButtonPaymentDataProviding {
  func paymentUrl(for yandexPayButton: any YPButtonProtocol) async throws -> String {
    guard !paymentURL.isEmpty else {
      throw RedirectsError.noPaymentURL
    }
    return paymentURL
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
