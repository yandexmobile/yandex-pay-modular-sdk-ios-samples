import SwiftUI
import YandexPayConfiguration
import YandexPayAuth
import YandexQuickPay

@main
struct YandexPaySDKModularSDKApp: App {

  private var merchant: YPSDKMerchant {
    .init(
      id: "<merchant-id>",
      name: "pay-sample-test",
      url: nil
    )
  }

  init() {
    YPay.initialize(
      environment: .production,
      locale: .en,
      modules: [
        YPayAuth.module(),
        YQuickPay.module(
          stateListener: QuickPayViewModel.shared,
          merchant: merchant,
          presentationContextProvider: SamplePresentationContextProvider.shared
        )
      ]
    )
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

private final class SamplePresentationContextProvider: YPPresentationContextProviding {
  static let shared = SamplePresentationContextProvider()

  func anchorForPresentation() -> YPPresentationContext {
    .keyWindow
  }
}
