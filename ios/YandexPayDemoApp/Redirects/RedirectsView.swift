import SwiftUI
import YandexPayWithRedirect
import YandexPayConfiguration

struct RedirectsView: View {
  @ObservedObject var orderSettings: OrderSettings
  @ObservedObject var urlProvider: PaymentURLProvider
  @StateObject private var viewModel: RedirectsViewModel

  init(orderSettings: OrderSettings, urlProvider: PaymentURLProvider) {
    self.orderSettings = orderSettings
    self.urlProvider = urlProvider
    _viewModel = StateObject(wrappedValue: RedirectsViewModel(urlProvider: urlProvider))
  }

  var body: some View {
    List {
      orderSection
      actionsSection
      if case .payment(let outcome) = viewModel.paymentResult {
        resultSection(outcome: outcome)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Redirects")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Sections

  private var orderSection: some View {
    Section {
      HStack {
        Text("Total")
        Spacer()
        Text("\(orderSettings.order.resolvedTotalString()) \(orderSettings.order.currencyCode)")
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Items")
        Spacer()
        Text("\(orderSettings.order.cartItems.count)")
          .foregroundStyle(.secondary)
      }
      NavigationLink("Edit Order") {
        OrderSettingsView(orderSettings: orderSettings, urlProvider: urlProvider)
      }
    } header: {
      Text("Order")
    }
  }

  private var actionsSection: some View {
    Section {
      viewModel.makePayButtonView(orderSettings: orderSettings)
        .frame(height: 48)
      Button("Open Pay Form") {
        Task { await viewModel.openPayForm() }
      }
      .disabled(urlProvider.isLoading)
      if urlProvider.isLoading {
        HStack { Spacer(); ProgressView(); Spacer() }
      }
      if let error = urlProvider.errorMessage {
        Text(error).foregroundStyle(.red).font(.footnote)
      }
    } header: {
      Text("Actions")
    }
  }

  private func resultSection(outcome: YPPaymentOutcome) -> some View {
    Section("Last Result") {
      Text(outcome.displayString)
        .foregroundStyle(outcome.isSucceeded ? .green : .secondary)
    }
  }
}
