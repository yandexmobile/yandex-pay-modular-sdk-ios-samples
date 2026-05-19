import SwiftUI
import YandexPayConfiguration
import YandexPayInventory

struct InventoryView: View {
  @State private var amount: String = "1000"
  @State private var badgeHeight: CGFloat = 24
  @State private var align: YPBadgeModel.Align = .center
  @State private var cashbackColor: YPBadgeModel.CashbackColor = .primary
  @State private var cashbackVariant: YPBadgeModel.CashbackVariant = .default
  @State private var splitColor: YPBadgeModel.SplitColor = .primary
  @State private var splitVariant: YPBadgeModel.SplitVariant = .simple

  private var amountValue: Decimal {
    Decimal(string: amount) ?? 1000
  }

  private var cashbackModel: YPBadgeModel {
    YPBadgeModel(
      amount: amountValue,
      currency: .rub,
      align: align,
      type: .cashback(color: cashbackColor, variant: cashbackVariant)
    )
  }

  private var splitModel: YPBadgeModel {
    YPBadgeModel(
      amount: amountValue,
      currency: .rub,
      align: align,
      type: .split(color: splitColor, variant: splitVariant)
    )
  }

  private var badgeView: any View {
    YPay.instance.inventory.createBadgeView(model: cashbackModel)
  }

  private var splitBadgeView: any View {
    YPay.instance.inventory.createBadgeView(model: splitModel)
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        AnyView(badgeView)
          .frame(height: badgeHeight)
          .padding(.horizontal, 16)

        AnyView(splitBadgeView)
          .frame(height: badgeHeight)
          .padding(.horizontal, 16)
      }
      .padding(.vertical, 20)
      .background(Color(.secondarySystemBackground))

      List {
        Section("Preview Size") {
          HStack {
            Text("Height")
            Slider(value: $badgeHeight, in: 12...40, step: 1) { EmptyView() }
            Text("\(Int(badgeHeight))")
              .monospacedDigit()
              .frame(width: 28, alignment: .trailing)
          }
        }

        Section("General") {
          HStack {
            Text("Amount (RUB)")
            Spacer()
            TextField("Amount", text: $amount)
              .multilineTextAlignment(.trailing)
              .keyboardType(.decimalPad)
              .frame(maxWidth: 100)
          }
          Picker("Align", selection: $align) {
            Text("Left").tag(YPBadgeModel.Align.left)
            Text("Center").tag(YPBadgeModel.Align.center)
            Text("Right").tag(YPBadgeModel.Align.right)
          }
        }

        Section("Cashback Badge") {
          Picker("Color", selection: $cashbackColor) {
            Text("Primary").tag(YPBadgeModel.CashbackColor.primary)
            Text("Grey").tag(YPBadgeModel.CashbackColor.grey)
            Text("Transparent").tag(YPBadgeModel.CashbackColor.transparent)
          }
          Picker("Variant", selection: $cashbackVariant) {
            Text("Default").tag(YPBadgeModel.CashbackVariant.default)
            Text("Compact").tag(YPBadgeModel.CashbackVariant.compact)
          }
        }

        Section("Split Badge") {
          Picker("Color", selection: $splitColor) {
            Text("Primary").tag(YPBadgeModel.SplitColor.primary)
            Text("Green").tag(YPBadgeModel.SplitColor.green)
            Text("Grey").tag(YPBadgeModel.SplitColor.grey)
            Text("Transparent").tag(YPBadgeModel.SplitColor.transparent)
          }
          Picker("Variant", selection: $splitVariant) {
            Text("Simple").tag(YPBadgeModel.SplitVariant.simple)
            Text("Detailed").tag(YPBadgeModel.SplitVariant.detailed)
          }
        }
      }
    }
    .navigationTitle("Inventory")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    InventoryView()
  }
}
