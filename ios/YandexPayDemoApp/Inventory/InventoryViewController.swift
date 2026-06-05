import UIKit
import YandexPayInventory
import YandexPayConfiguration

final class InventoryViewController: ScrollableViewController {

  // MARK: - State

  private var amount: Decimal = 1000
  private var badgeHeight: CGFloat = 24
  private var align: YPBadgeModel.Align = .center
  private var cashbackColor: YPBadgeModel.CashbackColor = .primary
  private var cashbackVariant: YPBadgeModel.CashbackVariant = .default
  private var splitColor: YPBadgeModel.SplitColor = .primary
  private var splitVariant: YPBadgeModel.SplitVariant = .simple

  // MARK: - UI

  private let badgePreviewContainer: UIView = {
    let v = UIView()
    v.backgroundColor = UIColor.secondarySystemBackground
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private var cashbackBadgeView: UIView?
  private var splitBadgeView: UIView?
  private var cashbackHeightConstraint: NSLayoutConstraint?
  private var splitHeightConstraint: NSLayoutConstraint?

  private let heightLabel = monoLabel("24")
  private let heightSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 12
    s.maximumValue = 40
    s.value = 24
    s.translatesAutoresizingMaskIntoConstraints = false
    return s
  }()

  private let amountTextField: UITextField = {
    let tf = UITextField()
    tf.text = "1000"
    tf.keyboardType = .decimalPad
    tf.textAlignment = .right
    tf.borderStyle = .roundedRect
    tf.translatesAutoresizingMaskIntoConstraints = false
    return tf
  }()

  private let alignControl = UISegmentedControl(items: ["Left", "Center", "Right"])
  private let cashbackColorControl = UISegmentedControl(items: ["Primary", "Grey", "Transparent"])
  private let cashbackVariantControl = UISegmentedControl(items: ["Default", "Compact"])
  private let splitColorControl = UISegmentedControl(items: ["Primary", "Green", "Grey", "Transparent"])
  private let splitVariantControl = UISegmentedControl(items: ["Simple", "Detailed"])

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupDefaultSegments()
    setupLayout()
    setupActions()
    rebuildBadges()
  }

  // MARK: - Default segment indices

  private func setupDefaultSegments() {
    alignControl.selectedSegmentIndex = 1
    cashbackColorControl.selectedSegmentIndex = 0
    cashbackVariantControl.selectedSegmentIndex = 0
    splitColorControl.selectedSegmentIndex = 0
    splitVariantControl.selectedSegmentIndex = 0
    [alignControl, cashbackColorControl, cashbackVariantControl,
     splitColorControl, splitVariantControl].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
  }

  // MARK: - Layout

  private func setupLayout() {
    let previewStack = vStack([], spacing: 8)
    badgePreviewContainer.addSubview(previewStack)
    NSLayoutConstraint.activate([
      previewStack.topAnchor.constraint(equalTo: badgePreviewContainer.topAnchor, constant: 20),
      previewStack.bottomAnchor.constraint(equalTo: badgePreviewContainer.bottomAnchor, constant: -20),
      previewStack.leadingAnchor.constraint(equalTo: badgePreviewContainer.leadingAnchor, constant: 16),
      previewStack.trailingAnchor.constraint(equalTo: badgePreviewContainer.trailingAnchor, constant: -16),
    ])

    let cashbackSlot = UIView(); cashbackSlot.translatesAutoresizingMaskIntoConstraints = false; cashbackSlot.tag = 101
    let splitSlot = UIView(); splitSlot.translatesAutoresizingMaskIntoConstraints = false; splitSlot.tag = 102
    previewStack.addArrangedSubview(cashbackSlot)
    previewStack.addArrangedSubview(splitSlot)

    heightLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true
    amountTextField.widthAnchor.constraint(equalToConstant: 100).isActive = true

    let contentStack = vStack([
      badgePreviewContainer,
      sectionCard(header: "Preview Size", contents: rowView(
        leading: label("Height", hugging: true),
        trailing: hStack([heightSlider, heightLabel])
      )),
      sectionCard(header: "General", contents: vStack([
        rowView(leading: label("Amount (RUB)", hugging: true), trailing: amountTextField),
        rowView(leading: label("Align", hugging: true), trailing: alignControl)
      ], spacing: 12)),
      sectionCard(header: "Cashback Badge", contents: vStack([
        rowView(leading: label("Color", hugging: true), trailing: cashbackColorControl),
        rowView(leading: label("Variant", hugging: true), trailing: cashbackVariantControl)
      ], spacing: 12)),
      sectionCard(header: "Split Badge", contents: vStack([
        rowView(leading: label("Color", hugging: true), trailing: splitColorControl),
        rowView(leading: label("Variant", hugging: true), trailing: splitVariantControl)
      ], spacing: 12))
    ], spacing: 16)

    installContent(contentStack, topPadding: 0)
  }

  // MARK: - Badge rebuild

  private func rebuildBadges() {
    guard let cashbackSlot = view.viewWithTag(101),
          let splitSlot = view.viewWithTag(102) else { return }

    cashbackBadgeView?.removeFromSuperview()
    splitBadgeView?.removeFromSuperview()
    cashbackHeightConstraint = nil
    splitHeightConstraint = nil

    let cashbackModel = YPBadgeModel(
      amount: amount, currency: .rub, align: align,
      type: .cashback(color: cashbackColor, variant: cashbackVariant)
    )
    let splitModel = YPBadgeModel(
      amount: amount, currency: .rub, align: align,
      type: .split(color: splitColor, variant: splitVariant)
    )

    func embed(_ badge: UIView, into slot: UIView, heightRef: inout NSLayoutConstraint?) {
      badge.translatesAutoresizingMaskIntoConstraints = false
      slot.addSubview(badge)
      let h = badge.heightAnchor.constraint(equalToConstant: badgeHeight)
      h.isActive = true
      heightRef = h
      NSLayoutConstraint.activate([
        badge.topAnchor.constraint(equalTo: slot.topAnchor),
        badge.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
        badge.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
        badge.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
      ])
    }

    let cb: UIView = YPay.instance.inventory.createBadgeView(model: cashbackModel)
    embed(cb, into: cashbackSlot, heightRef: &cashbackHeightConstraint)
    cashbackBadgeView = cb

    let sp: UIView = YPay.instance.inventory.createBadgeView(model: splitModel)
    embed(sp, into: splitSlot, heightRef: &splitHeightConstraint)
    splitBadgeView = sp
  }

  private func updateBadgeHeights() {
    cashbackHeightConstraint?.constant = badgeHeight
    splitHeightConstraint?.constant = badgeHeight
  }

  // MARK: - Actions

  private func setupActions() {
    heightSlider.addTarget(self, action: #selector(heightChanged), for: .valueChanged)
    amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
    alignControl.addTarget(self, action: #selector(alignChanged), for: .valueChanged)
    cashbackColorControl.addTarget(self, action: #selector(cashbackColorChanged), for: .valueChanged)
    cashbackVariantControl.addTarget(self, action: #selector(cashbackVariantChanged), for: .valueChanged)
    splitColorControl.addTarget(self, action: #selector(splitColorChanged), for: .valueChanged)
    splitVariantControl.addTarget(self, action: #selector(splitVariantChanged), for: .valueChanged)
    addKeyboardDismissGesture()
  }

  @objc private func heightChanged() {
    badgeHeight = CGFloat(heightSlider.value)
    heightLabel.text = "\(Int(badgeHeight))"
    updateBadgeHeights()
  }

  @objc private func amountChanged() {
    amount = Decimal(string: amountTextField.text ?? "") ?? 1000
    rebuildBadges()
  }

  @objc private func alignChanged() {
    align = [.left, .center, .right][alignControl.selectedSegmentIndex]
    rebuildBadges()
  }

  @objc private func cashbackColorChanged() {
    cashbackColor = [.primary, .grey, .transparent][cashbackColorControl.selectedSegmentIndex]
    rebuildBadges()
  }

  @objc private func cashbackVariantChanged() {
    cashbackVariant = [.default, .compact][cashbackVariantControl.selectedSegmentIndex]
    rebuildBadges()
  }

  @objc private func splitColorChanged() {
    splitColor = [.primary, .green, .grey, .transparent][splitColorControl.selectedSegmentIndex]
    rebuildBadges()
  }

  @objc private func splitVariantChanged() {
    splitVariant = [.simple, .detailed][splitVariantControl.selectedSegmentIndex]
    rebuildBadges()
  }
}
