import SwiftUI
import YandexPayConfiguration

struct ContentView: View {

  var body: some View {
    NavigationStack {
      List {
        NavigationLink("Auth") {
          AuthView()
        }
        NavigationLink("Quick Pay") {
          QuickPayView(viewModel: .shared)
        }
        NavigationLink("Pay Widget") {
          PayWidgetView()
        }
        NavigationLink("Redirects") {
          RedirectsView()
        }
        NavigationLink("Inventory") {
          InventoryView()
        }
        NavigationLink("Assistant") {
          AssistantView()
        }
      }
      .navigationTitle("Modular SDK")
    }
  }
}

#Preview {
  ContentView()
}
