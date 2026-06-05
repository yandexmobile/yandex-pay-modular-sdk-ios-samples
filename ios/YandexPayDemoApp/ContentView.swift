import SwiftUI
import YandexPayConfiguration

struct ContentView: View {

  @AppStorage("useUIKit") private var useUIKit: Bool = false
  @StateObject private var orderSettings: OrderSettings
  @StateObject private var urlProvider: PaymentURLProvider

  init() {
    let settings = OrderSettings()
    _orderSettings = StateObject(wrappedValue: settings)
    _urlProvider = StateObject(wrappedValue: PaymentURLProvider(orderSettings: settings))
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          Picker("UI Framework", selection: $useUIKit) {
            Text("SwiftUI").tag(false)
            Text("UIKit").tag(true)
          }
          .pickerStyle(.segmented)
        }

        NavigationLink("Order Settings") {
          OrderSettingsView(orderSettings: orderSettings, urlProvider: urlProvider)
        }

        NavigationLink("Auth") {
          if useUIKit {
            UIKitWrapper { AuthViewController() }
              .navigationTitle("Auth")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            AuthView()
          }
        }
        NavigationLink("CP QR (Quick Pay)") {
          if useUIKit {
            UIKitWrapper { QuickPayViewController() }
              .navigationTitle("CP QR (Quick Pay)")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            QuickPayView(viewModel: .shared)
          }
        }
        NavigationLink("In App (Pay Widget)") {
          if useUIKit {
            UIKitWrapper { PayWidgetViewController(orderSettings: orderSettings, urlProvider: urlProvider) }
              .navigationTitle("In App (Pay Widget)")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            PayWidgetView(orderSettings: orderSettings, urlProvider: urlProvider)
          }
        }
        NavigationLink("Redirects") {
          if useUIKit {
            UIKitWrapper { RedirectsViewController(orderSettings: orderSettings, urlProvider: urlProvider) }
              .navigationTitle("Redirects")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            RedirectsView(orderSettings: orderSettings, urlProvider: urlProvider)
          }
        }
        NavigationLink("Inventory") {
          if useUIKit {
            UIKitWrapper { InventoryViewController() }
              .navigationTitle("Inventory")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            InventoryView()
          }
        }
        NavigationLink("Assistant") {
          if useUIKit {
            UIKitWrapper { AssistantViewController() }
              .navigationTitle("Assistant")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            AssistantView()
          }
        }
      }
      .navigationTitle("Yandex Pay Kit")
    }
  }
}

#Preview {
  ContentView()
}
