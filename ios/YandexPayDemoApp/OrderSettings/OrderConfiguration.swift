import Foundation
import YandexPayConfiguration

struct CartItem: Codable, Equatable, Identifiable {
  var id: UUID
  var productId: String
  var title: String
  var total: String
  var quantityCount: String

  init(id: UUID = UUID(), productId: String, title: String, total: String, quantityCount: String) {
    self.id = id
    self.productId = productId
    self.title = title
    self.total = total
    self.quantityCount = quantityCount
  }
}

struct OrderConfiguration: Codable, Equatable {
  var cartItems: [CartItem]
  var currencyCode: String
  var availablePaymentMethods: [String]
  var ttlSeconds: Int
  var redirectOnSuccess: String
  var redirectOnError: String
  var redirectOnAbort: String

  static let `default` = OrderConfiguration(
    cartItems: [
      CartItem(productId: "pid-0", title: "Item 1", total: "1000", quantityCount: "1.0"),
      CartItem(productId: "pid-1", title: "Item 2", total: "600", quantityCount: "1.0")
    ],
    currencyCode: "RUB",
    availablePaymentMethods: ["CARD"],
    ttlSeconds: 0,
    redirectOnSuccess: "ypay://finish/success.html",
    redirectOnError: "ypay://finish/error.html",
    redirectOnAbort: "ypay://finish/abort.html"
  )

  func resolvedTotalString() -> String {
    let sum = cartItems.reduce(0.0) { acc, item in
      acc + (Double(item.total.replacingOccurrences(of: ",", with: ".")) ?? 0)
    }
    if sum == floor(sum), !sum.isNaN, !sum.isInfinite { return String(Int(sum)) }
    return String(sum)
  }

  func resolvedTotalDecimal() -> Decimal {
    Decimal(string: resolvedTotalString()) ?? 0
  }

  func resolvedCurrency() -> YPCurrencyCode {
    let code = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return YPCurrencyCode(rawValue: code) ?? .rub
  }
}

enum KnownPaymentMethod: String, CaseIterable {
  case card = "CARD"
  case split = "SPLIT"
}
