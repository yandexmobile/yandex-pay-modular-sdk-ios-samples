import SwiftUI
import YandexPayInApp
import YandexPayWithRedirect
import YandexPayConfiguration

struct PayWidgetView: View {
  @StateObject private var viewModel = PayWidgetViewModel()
  @State private var widgetWidth: CGFloat = UIScreen.main.bounds.width

  private var redirectButton: any View {
    YPay.instance.payWithRedirect.createButton(
      model: .default,
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

        AnyView(
          redirectButton
        )
        .frame(height: 48)
        .padding(.horizontal, 16)

        List {
          Section {
            HStack {
              Text("Widget state")
              Spacer()
              Text(viewModel.widgetState)
                .foregroundStyle(.secondary)
            }
          }

          Section {
            Toggle("Send amount to widget", isOn: $viewModel.passAmount)
            if viewModel.passAmount {
              HStack {
                Text("Amount (RUB)")
                Spacer()
                TextField("Amount", text: $viewModel.amount)
                  .multilineTextAlignment(.trailing)
                  .keyboardType(.decimalPad)
                  .frame(maxWidth: 100)
              }
            }
          } header: {
            Text("Order Amount")
          }

          Section {
            HStack {
              Text("Width")
              Slider(
                value: $widgetWidth,
                in: 240...UIScreen.main.bounds.width,
                step: 1
              ) { EmptyView() }
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
    .navigationTitle("Pay Widget")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    PayWidgetView()
  }
}
