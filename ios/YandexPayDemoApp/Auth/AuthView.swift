import SwiftUI
import YandexPayAuth

struct AuthView: View {

  @StateObject private var viewModel = AuthViewModel()

  var body: some View {
    VStack(spacing: 16) {
      Text("Authorization")
        .font(.headline)

      Picker("Strategy", selection: $viewModel.selectedStrategy) {
        Text("Default").tag(YPAuthorizationStrategy.default)
        Text("Web Only").tag(YPAuthorizationStrategy.webOnly)
        Text("Primary Only").tag(YPAuthorizationStrategy.primaryOnly)
      }
      .pickerStyle(.segmented)
      .disabled(viewModel.isLoading || viewModel.isLoggedIn)

      HStack(spacing: 12) {
        Button("Login") {
          viewModel.login()
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading || viewModel.isLoggedIn)

        Button("Logout") {
          viewModel.logout()
        }
        .buttonStyle(.bordered)
        .disabled(!viewModel.isLoggedIn)
      }

      if viewModel.isLoading {
        ProgressView("Authorizing…")
          .font(.caption)
      }

      if let error = viewModel.errorMessage {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      Label(
        viewModel.isLoggedIn ? "Logged in" : "Not logged in",
        systemImage: viewModel.isLoggedIn ? "checkmark.circle.fill" : "circle"
      )
      .foregroundStyle(viewModel.isLoggedIn ? .green : .secondary)
      .font(.caption)
      .animation(.default, value: viewModel.isLoggedIn)
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(radius: 8)
  }
}
