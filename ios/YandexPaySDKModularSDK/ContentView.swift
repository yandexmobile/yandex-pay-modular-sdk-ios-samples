import SwiftUI
import YandexPayConfiguration

struct ContentView: View {

  @AppStorage("useUIKit") private var useUIKit: Bool = false

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

        NavigationLink("Auth") {
          if useUIKit {
            UIKitWrapper { AuthViewController() }
              .navigationTitle("Auth")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            AuthView()
          }
        }
        NavigationLink("Quick Pay") {
          if useUIKit {
            UIKitWrapper { QuickPayViewController() }
              .navigationTitle("Quick Pay")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            QuickPayView(viewModel: .shared)
          }
        }
        NavigationLink("Pay Widget") {
          if useUIKit {
            UIKitWrapper { PayWidgetViewController() }
              .navigationTitle("Pay Widget")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            PayWidgetView()
          }
        }
        NavigationLink("Redirects") {
          if useUIKit {
            UIKitWrapper { RedirectsViewController() }
              .navigationTitle("Redirects")
              .navigationBarTitleDisplayMode(.inline)
          } else {
            RedirectsView()
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
