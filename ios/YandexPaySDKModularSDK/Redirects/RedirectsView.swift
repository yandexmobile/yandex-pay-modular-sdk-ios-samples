import SwiftUI
import YandexPayWithRedirect
import YandexPayConfiguration

struct RedirectsView: View {
  @StateObject private var viewModel = RedirectsViewModel()

  var body: some View {
    List {
      Section {
        TextField("https://...", text: $viewModel.paymentURL)
          .autocapitalization(.none)
          .disableAutocorrection(true)
          .keyboardType(.URL)
      } header: {
        Text("Payment URL")
      } footer: {
        Text("Enter a Yandex Pay payment URL to use with the pay button or form.")
      }

      Section("Actions") {
        viewModel.makePayButtonView()
          .frame(height: 48)

        Button("Open Pay Form") {
          viewModel.openPayForm()
        }
      }

      if case .payment(let outcome) = viewModel.paymentResult {
        Section("Last Result") {
          Text(outcome.displayString)
            .foregroundStyle(outcome.isSucceeded ? .green : .secondary)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Redirects")
    .navigationBarTitleDisplayMode(.inline)
  }
}
