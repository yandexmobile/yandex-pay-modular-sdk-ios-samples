import UIKit
import Combine
import YandexPayAuth
import YandexPayConfiguration

@MainActor
final class AuthViewModel: ObservableObject {

  @Published var selectedStrategy: YPAuthorizationStrategy = .default
  @Published var isLoggedIn: Bool = false
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil

  private var auth: YPayAuth {
    YPay.instance.auth
  }

  func login() {
    guard !isLoading else { return }
    guard let presenter = topViewController() else {
      errorMessage = "No presenter available"
      return
    }
    isLoading = true
    errorMessage = nil
    Task {
      do {
        _ = try await auth.authorize(strategy: selectedStrategy, with: presenter)
        isLoggedIn = true
      } catch {
        errorMessage = String(describing: error)
        print("Auth error: \(error)")
      }
      isLoading = false
    }
  }

  func logout() {
    auth.logout()
    isLoggedIn = false
    errorMessage = nil
  }

  private func topViewController() -> UIViewController? {
    UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
  }
}
