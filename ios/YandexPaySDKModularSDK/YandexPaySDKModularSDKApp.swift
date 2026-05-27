import SwiftUI
import YandexPayConfiguration
import YandexPayAuth
import YandexQuickPay
import YandexPayInventory
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayAssistant

@main
struct YandexPaySDKModularSDKApp: App {

  private var merchant: YPSDKMerchant {
    .init(
      id: "a5f49c84-0baa-41e1-814f-6f99746a6987",
      name: "yandex-pay-kit-sample-test",
      url: nil
    )
  }

  init() {
    YPay.initialize(
      environment: .sandbox,
      locale: .ru,
      modules: [
        YPayAuth.module(),
        YQuickPay.module(
          stateListener: QuickPayViewModel.shared,
          merchant: merchant,
          presentationContextProvider: SamplePresentationContextProvider.shared
        ),
        YPayInventory.module(merchant: merchant),
        YPayWithRedirect.module(merchant: merchant),
        YPayInApp.module(merchant: merchant),
        YPAssistantModule.module(merchant: merchant)
      ]
    )
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

final class SamplePresentationContextProvider: YPPresentationContextProviding {
  static let shared = SamplePresentationContextProvider()

  func anchorForPresentation() -> YPPresentationContext {
    .keyWindow
  }
}
