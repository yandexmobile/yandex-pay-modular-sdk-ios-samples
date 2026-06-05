import Foundation
import Combine

@MainActor
final class OrderSettings: ObservableObject {
  @Published var order: OrderConfiguration = .default
}
