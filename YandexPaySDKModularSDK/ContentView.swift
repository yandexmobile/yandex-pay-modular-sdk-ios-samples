import SwiftUI

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
      }
      .navigationTitle("Modular SDK")
    }
  }
}

#Preview {
  ContentView()
}
