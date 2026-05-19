import SwiftUI
import YandexPayAssistant
import YandexPayConfiguration

struct AssistantView: View {
  @State private var screen: YPBenefitsWidgetScreen? = .product
  @State private var clickability: YPBenefitsWidgetClickability = .always
  @State private var widgetWidth: CGFloat = UIScreen.main.bounds.width - 32

  private static let screens: [YPBenefitsWidgetScreen?] = [nil] + YPBenefitsWidgetScreen.allCases.map { Optional($0) }

  private var benifitWidget: any View {
    YPay.instance.assistant.createBenefitsWidget(
      screen: screen,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      clickability: clickability
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      AnyView(
        benifitWidget
      )
      .fixedSize(horizontal: false, vertical: true)
      .frame(width: widgetWidth)
      .padding(.vertical, 20)
      .background(Color(.secondarySystemBackground))

      List {
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

        Section("Configuration") {
          Picker("Screen", selection: $screen) {
            Text("None").tag(Optional<YPBenefitsWidgetScreen>.none)
            ForEach(YPBenefitsWidgetScreen.allCases, id: \.self) { s in
              Text(s.rawValue.capitalized).tag(Optional(s))
            }
          }
          Picker("Clickability", selection: $clickability) {
            Text("Always").tag(YPBenefitsWidgetClickability.always)
            Text("Only Authorized").tag(YPBenefitsWidgetClickability.onlyAuthorized)
          }
        }
      }
    }
    .navigationTitle("Assistant")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    AssistantView()
  }
}
