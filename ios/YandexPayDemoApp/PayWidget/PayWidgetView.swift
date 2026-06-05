import SwiftUI
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayConfiguration

struct PayWidgetView: View {
  @ObservedObject var orderSettings: OrderSettings
  @ObservedObject var urlProvider: PaymentURLProvider
  @StateObject private var viewModel: PayWidgetViewModel
  @State private var widgetWidth: CGFloat = UIScreen.main.bounds.width

  init(orderSettings: OrderSettings, urlProvider: PaymentURLProvider) {
    self.orderSettings = orderSettings
    self.urlProvider = urlProvider
    _viewModel = StateObject(wrappedValue: PayWidgetViewModel(
      orderSettings: orderSettings,
      urlProvider: urlProvider
    ))
  }

  private var redirectButton: any View {
    YPay.instance.payWithRedirect.createButton(
      model: YPButtonModel(
        amount: orderSettings.order.resolvedTotalDecimal(),
        currency: orderSettings.order.resolvedCurrency()
      ),
      paymentDataProvider: viewModel,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      delegate: viewModel
    )
  }

  var body: some View {
    ZStack {
      Color.green.opacity(0.08).ignoresSafeArea()

      VStack(spacing: 16) {
        AnyView(
          YPay.instance.payInApp.createPayWidgetView(
            model: viewModel.payWidgetModel,
            presentationContextProvider: SamplePresentationContextProvider.shared
          )
        )
        .fixedSize(horizontal: false, vertical: true)
        .id(viewModel.widgetIdentity)
        .frame(width: widgetWidth)

        AnyView(redirectButton)
          .frame(height: 48)
          .padding(.horizontal, 16)

        if urlProvider.isLoading {
          ProgressView().padding(.top, 4)
        }
        if let error = urlProvider.errorMessage {
          Text(error)
            .foregroundStyle(.red)
            .font(.footnote)
            .padding(.horizontal, 16)
        }

        List {
          Section {
            HStack {
              Text("Widget state")
              Spacer()
              Text(viewModel.widgetState).foregroundStyle(.secondary)
            }
          }

          Section {
            HStack {
              Text("Total")
              Spacer()
              Text("\(orderSettings.order.resolvedTotalString()) \(orderSettings.order.currencyCode)")
                .foregroundStyle(.secondary)
            }
            Toggle("Send amount to widget", isOn: $viewModel.passAmount)
            NavigationLink("Edit Order") {
              OrderSettingsView(orderSettings: orderSettings, urlProvider: urlProvider)
            }
          } header: {
            Text("Order")
          }

          Section {
            HStack {
              Text("Width")
              Slider(value: $widgetWidth, in: 240...UIScreen.main.bounds.width, step: 1) {
                EmptyView()
              }
              Text("\(Int(widgetWidth))")
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
            }
          } header: {
            Text("Size")
          }
        }
        .scrollDismissesKeyboard(.immediately)
      }
    }
    .overlay(alignment: .bottom) {
      if let result = viewModel.paymentResult {
        Text(result)
          .font(.subheadline.weight(.medium))
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial)
          .clipShape(Capsule())
          .padding(.bottom, 24)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(duration: 0.35), value: viewModel.paymentResult != nil)
    .onAppear {
      YPay.instance.payInApp.setStateDelegate(viewModel)
    }
    .navigationTitle("In App (Pay Widget)")
    .navigationBarTitleDisplayMode(.inline)
  }
}
