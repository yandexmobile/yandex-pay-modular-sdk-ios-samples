import Foundation
import Combine

import YandexPayConfiguration

@MainActor
final class PaymentURLProvider: ObservableObject {
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  private let orderSettings: OrderSettings
  private let service = CreateOrderService()
  private var loadingTask: Task<URL?, Never>?

  let environment: YPSDKEnvironment = .sandbox

  init(orderSettings: OrderSettings) {
    self.orderSettings = orderSettings
  }

  // Always creates a fresh order for each payment attempt.
  func resolvePaymentURL(flow: PaymentFlow? = nil) async -> URL? {
    if let task = loadingTask { return await task.value }
    return await generatePaymentURL(flow: flow)
  }

  @discardableResult
  private func generatePaymentURL(flow: PaymentFlow? = nil) async -> URL? {
    if let task = loadingTask { return await task.value }

    let task = Task<URL?, Never> { @MainActor [weak self] in
      guard let self else { return nil }
      isLoading = true
      errorMessage = nil
      defer {
        isLoading = false
        loadingTask = nil
      }
      do {
        let url = try await service.createOrder(
          apiKey: DemoMerchant.sandboxApiKey,
          environment: environment,
          flow: flow,
          order: orderSettings.order
        )
        return url
      } catch {
        errorMessage = error.localizedDescription
        return nil
      }
    }
    loadingTask = task
    return await task.value
  }

  func clearError() {
    errorMessage = nil
    loadingTask?.cancel()
    loadingTask = nil
  }
}
