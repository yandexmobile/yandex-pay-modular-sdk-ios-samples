import UIKit
import YandexPayAssistant
import YandexPayConfiguration

final class AssistantViewController: ScrollableViewController {

  // MARK: - State

  private var screen: YPBenefitsWidgetScreen? = .product
  private var clickability: YPBenefitsWidgetClickability = .always
  private var widgetWidth: CGFloat = UIScreen.main.bounds.width - 32

  // MARK: - UI

  private let widgetPreviewContainer: UIView = {
    let v = UIView()
    v.backgroundColor = UIColor.secondarySystemBackground
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private var currentWidgetView: UIView?
  private var widgetWidthConstraint: NSLayoutConstraint?

  private let widthLabel = monoLabel("")
  private let widthSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 240
    s.maximumValue = Float(UIScreen.main.bounds.width)
    s.translatesAutoresizingMaskIntoConstraints = false
    return s
  }()

  private let screenButton: UIButton = {
    var config = UIButton.Configuration.bordered()
    config.title = "Product"
    config.image = UIImage(systemName: "chevron.up.chevron.down")
    config.imagePlacement = .trailing
    config.imagePadding = 4
    config.buttonSize = .small
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.changesSelectionAsPrimaryAction = false
    button.showsMenuAsPrimaryAction = true
    return button
  }()

  private let clickabilityControl = UISegmentedControl(items: ["Always", "Only Auth"])

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    widthSlider.value = Float(widgetWidth)
    widthLabel.text = "\(Int(widgetWidth))"

    clickabilityControl.selectedSegmentIndex = 0
    clickabilityControl.translatesAutoresizingMaskIntoConstraints = false

    buildScreenMenu()
    setupLayout()
    setupActions()
    rebuildWidget()
  }

  // MARK: - Layout

  private func setupLayout() {
    widthLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true

    let contentStack = vStack([
      widgetPreviewContainer,
      sectionCard(header: "Size", contents: hStack([
        label("Width", hugging: true), widthSlider, widthLabel
      ])),
      sectionCard(header: "Configuration", contents: vStack([
        rowView(leading: label("Screen", hugging: true), trailing: screenButton),
        rowView(leading: label("Clickability", hugging: true), trailing: clickabilityControl)
      ], spacing: 12))
    ], spacing: 16)

    installContent(contentStack, topPadding: 0)
  }

  // MARK: - Widget rebuild

  private func rebuildWidget() {
    currentWidgetView?.removeFromSuperview()
    widgetWidthConstraint = nil

    let widget: UIView = YPay.instance.assistant.createBenefitsWidget(
      screen: screen,
      presentationContextProvider: SamplePresentationContextProvider.shared,
      clickability: clickability
    )
    widget.translatesAutoresizingMaskIntoConstraints = false
    widgetPreviewContainer.addSubview(widget)

    let wc = widget.widthAnchor.constraint(equalToConstant: widgetWidth)
    wc.isActive = true
    widgetWidthConstraint = wc

    NSLayoutConstraint.activate([
      widget.topAnchor.constraint(equalTo: widgetPreviewContainer.topAnchor, constant: 20),
      widget.bottomAnchor.constraint(equalTo: widgetPreviewContainer.bottomAnchor, constant: -20),
      widget.centerXAnchor.constraint(equalTo: widgetPreviewContainer.centerXAnchor),
    ])
    currentWidgetView = widget
  }

  // MARK: - Actions

  private func setupActions() {
    widthSlider.addTarget(self, action: #selector(widthChanged), for: .valueChanged)
    clickabilityControl.addTarget(self, action: #selector(clickabilityChanged), for: .valueChanged)
  }

  private func buildScreenMenu() {
    let noneAction = UIAction(title: "None", state: screen == nil ? .on : .off) { [weak self] _ in
      self?.screen = nil
      self?.updateScreenButtonTitle()
      self?.rebuildWidget()
    }

    let screenActions = YPBenefitsWidgetScreen.allCases.map { s in
      UIAction(title: s.rawValue.capitalized, state: self.screen == s ? .on : .off) { [weak self] _ in
        self?.screen = s
        self?.updateScreenButtonTitle()
        self?.rebuildWidget()
      }
    }

    screenButton.menu = UIMenu(children: [noneAction] + screenActions)
    updateScreenButtonTitle()
  }

  private func updateScreenButtonTitle() {
    let title = screen.map { $0.rawValue.capitalized } ?? "None"
    var config = screenButton.configuration
    config?.title = title
    screenButton.configuration = config
  }

  @objc private func widthChanged() {
    widgetWidth = CGFloat(widthSlider.value)
    widthLabel.text = "\(Int(widgetWidth))"
    widgetWidthConstraint?.constant = widgetWidth
  }

  @objc private func clickabilityChanged() {
    clickability = clickabilityControl.selectedSegmentIndex == 0 ? .always : .onlyAuthorized
    rebuildWidget()
  }
}
