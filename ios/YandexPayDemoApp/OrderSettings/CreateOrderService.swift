import Foundation
import YandexPayConfiguration

enum PaymentFlow: String {
  case sbpOnly = "SBP_ONLY"
}

final class CreateOrderService {

  func createOrder(
    apiKey: String,
    environment: YPSDKEnvironment,
    flow: PaymentFlow?,
    order: OrderConfiguration
  ) async throws -> URL {
    guard let url = URL(string: environment.payBackendBaseURL + "/api/merchant/v1/orders") else {
      throw CreateOrderError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(flow: flow, order: order))

    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(CreateOrderResponse.self, from: data)

    guard
      let urlString = response.data?.paymentUrl,
      let paymentURL = URL(string: urlString)
    else {
      throw CreateOrderError.missingPaymentURL
    }
    return paymentURL
  }

  private func requestBody(flow: PaymentFlow?, order: OrderConfiguration) -> [String: Any] {
    var body: [String: Any] = [
      "orderId": "\(Date())",
      "redirectUrls": [
        "onSuccess": order.redirectOnSuccess,
        "onError": order.redirectOnError,
        "onAbort": order.redirectOnAbort
      ],
      "ttl": order.ttlSeconds,
      "currencyCode": order.currencyCode,
      "availablePaymentMethods": order.availablePaymentMethods,
      "cart": [
        "total": ["amount": order.resolvedTotalString()],
        "items": order.cartItems.map { item in
          [
            "quantity": ["count": item.quantityCount],
            "title": item.title,
            "productId": item.productId,
            "total": item.total
          ]
        }
      ]
    ]
    if let flow {
      body["flow"] = flow.rawValue
    }
    return body
  }
}

// MARK: - Errors

enum CreateOrderError: LocalizedError {
  case invalidURL
  case missingPaymentURL

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid API endpoint URL"
    case .missingPaymentURL: return "Server returned no payment URL"
    }
  }
}

// MARK: - Response

private struct CreateOrderResponse: Decodable {
  struct Data: Decodable { let paymentUrl: String? }
  let data: Data?
}

// MARK: - YPSDKEnvironment base URL

extension YPSDKEnvironment {
  var payBackendBaseURL: String {
    switch self {
    case .sandbox: return "https://sandbox.pay.yandex.ru"
    case .production: return "https://pay.yandex.ru"
    @unknown default: return "https://sandbox.pay.yandex.ru"
    }
  }
}
