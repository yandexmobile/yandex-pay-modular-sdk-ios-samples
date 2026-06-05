import SwiftUI
import YandexPayConfiguration
import YandexPayAuth
import YandexQuickPay
import YandexPayInventory
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayAssistant

@main
struct YandexPayDemoApp: App {

  private let merchant = YPSDKMerchant(
    id: DemoMerchant.id,
    name: DemoMerchant.name,
    url: nil
  )

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
        .onOpenURL { url in
          guard YPay.isInitialized else { return }
          YPay.instance.deeplinkHandler.handleOpenURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
          guard YPay.isInitialized else { return }
          YPay.instance.deeplinkHandler.handleUserActivity(activity)
        }
    }
  }
}

final class SamplePresentationContextProvider: YPPresentationContextProviding {
  static let shared = SamplePresentationContextProvider()

  func anchorForPresentation() -> YPPresentationContext {
    .keyWindow
  }
}
