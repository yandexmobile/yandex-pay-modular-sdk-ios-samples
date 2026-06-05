import SwiftUI

struct OrderSettingsView: View {
  @ObservedObject var orderSettings: OrderSettings
  @ObservedObject var urlProvider: PaymentURLProvider
  @State private var isCartEditorPresented = false

  var body: some View {
    Form {
      summarySection
      methodsSection
      currencySection
      resetSection
    }
    .navigationTitle("Order Settings")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
        isCartEditorPresented = true
        } label: {
          Image(systemName: "cart")
        }
        .accessibilityLabel("Edit cart")
      }
    }
    .sheet(isPresented: $isCartEditorPresented) {
      NavigationView {
        CartEditorView(orderSettings: orderSettings, urlProvider: urlProvider)
      }
      .interactiveDismissDisabled()
    }
  }

  // MARK: - Sections

  private var summarySection: some View {
    Section("Cart Summary") {
      HStack {
        Text("Items")
        Spacer()
        Text("\(orderSettings.order.cartItems.count)")
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Total")
        Spacer()
        Text("\(orderSettings.order.resolvedTotalString()) \(orderSettings.order.currencyCode)")
          .foregroundStyle(.secondary)
      }
    }
  }

  private var methodsSection: some View {
    Section {
      ForEach(KnownPaymentMethod.allCases, id: \.rawValue) { method in
        Toggle(method.rawValue, isOn: methodBinding(method.rawValue))
      }
    } header: {
      Text("Payment Methods")
    } footer: {
      Text("At least one method must stay enabled.")
    }
  }

  private var currencySection: some View {
    Section("Currency") {
      TextField("RUB", text: $orderSettings.order.currencyCode)
        .textInputAutocapitalization(.characters)
    }
  }

  private var resetSection: some View {
    Section {
      Button("Reset to Defaults", role: .destructive) {
        orderSettings.order = .default
        urlProvider.clearError()
      }
    }
  }

  // MARK: - Bindings

  private func methodBinding(_ code: String) -> Binding<Bool> {
    Binding(
      get: { orderSettings.order.availablePaymentMethods.contains(code) },
      set: { isOn in
        var methods = Set(orderSettings.order.availablePaymentMethods)
        if isOn { methods.insert(code) } else { methods.remove(code) }
        if methods.isEmpty { methods.insert(code) }
        orderSettings.order.availablePaymentMethods = Array(methods).sorted()
        urlProvider.clearError()
      }
    )
  }
}

// MARK: - Cart editor

struct CartEditorView: View {
  @ObservedObject var orderSettings: OrderSettings
  @ObservedObject var urlProvider: PaymentURLProvider
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      ForEach(orderSettings.order.cartItems) { item in
        NavigationLink {
          CartItemEditorView(item: itemBinding(id: item.id))
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.title.isEmpty ? "(untitled)" : item.title)
              .font(.headline)
            Text("id: \(item.productId) · total: \(item.total)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .onDelete { offsets in
        orderSettings.order.cartItems.remove(atOffsets: offsets)
        urlProvider.clearError()
      }

      Button {
        orderSettings.order.cartItems.append(
          CartItem(productId: "pid-new", title: "New item", total: "100", quantityCount: "1.0")
        )
      } label: {
        Label("Add item", systemImage: "plus.circle.fill")
      }
    }
    .navigationTitle("Cart")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Done") { dismiss() }
      }
    }
  }

  private func itemBinding(id: UUID) -> Binding<CartItem> {
    Binding(
      get: {
        orderSettings.order.cartItems.first { $0.id == id }
          ?? CartItem(productId: "", title: "", total: "0", quantityCount: "1.0")
      },
      set: { newValue in
        guard let index = orderSettings.order.cartItems.firstIndex(where: { $0.id == id }) else { return }
        orderSettings.order.cartItems[index] = newValue
        urlProvider.clearError()
      }
    )
  }
}

// MARK: - Cart item editor

private struct CartItemEditorView: View {
  @Binding var item: CartItem

  var body: some View {
    Form {
      TextField("productId", text: $item.productId)
      TextField("title", text: $item.title)
      TextField("total", text: $item.total)
        .keyboardType(.decimalPad)
      TextField("quantity.count", text: $item.quantityCount)
        .keyboardType(.decimalPad)
    }
    .navigationTitle("Item")
    .navigationBarTitleDisplayMode(.inline)
  }
}
