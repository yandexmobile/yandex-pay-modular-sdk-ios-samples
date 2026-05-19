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
