import UIKit

// MARK: - Stack builders

func hStack(_ views: [UIView], spacing: CGFloat = 8, alignment: UIStackView.Alignment = .center) -> UIStackView {
  let s = UIStackView(arrangedSubviews: views)
  s.axis = .horizontal
  s.spacing = spacing
  s.alignment = alignment
  s.translatesAutoresizingMaskIntoConstraints = false
  return s
}

func vStack(_ views: [UIView], spacing: CGFloat = 12) -> UIStackView {
  let s = UIStackView(arrangedSubviews: views)
  s.axis = .vertical
  s.spacing = spacing
  s.translatesAutoresizingMaskIntoConstraints = false
  return s
}

// MARK: - Labels

func label(
  _ text: String,
  style: UIFont.TextStyle = .body,
  color: UIColor = .label,
  hugging: Bool = false
) -> UILabel {
  let l = UILabel()
  l.text = text
  l.font = .preferredFont(forTextStyle: style)
  l.textColor = color
  l.translatesAutoresizingMaskIntoConstraints = false
  if hugging { l.setContentHuggingPriority(.defaultHigh, for: .horizontal) }
  return l
}

func monoLabel(_ text: String) -> UILabel {
  let l = UILabel()
  l.text = text
  l.font = .monospacedDigitSystemFont(
    ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
    weight: .regular
  )
  l.textAlignment = .right
  l.translatesAutoresizingMaskIntoConstraints = false
  return l
}

// MARK: - Row

func rowView(leading: UIView, trailing: UIView) -> UIView {
  hStack([leading, trailing])
}

// MARK: - Buttons

func yButton(_ title: String, filled: Bool = false, size: UIButton.Configuration.Size = .medium) -> UIButton {
  var config = filled ? UIButton.Configuration.filled() : UIButton.Configuration.bordered()
  config.title = title
  config.buttonSize = size
  let button = UIButton(configuration: config)
  button.translatesAutoresizingMaskIntoConstraints = false
  return button
}

// MARK: - Cards

func card(contents: UIView, radius: CGFloat = 16) -> UIView {
  let v = UIView()
  v.backgroundColor = .secondarySystemGroupedBackground
  v.layer.cornerRadius = radius
  v.layer.cornerCurve = .continuous
  v.translatesAutoresizingMaskIntoConstraints = false
  contents.translatesAutoresizingMaskIntoConstraints = false
  v.addSubview(contents)
  NSLayoutConstraint.activate([
    contents.topAnchor.constraint(equalTo: v.topAnchor, constant: 12),
    contents.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -12),
    contents.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
    contents.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
  ])
  return v
}

func sectionCard(header: String, footer: String? = nil, contents: UIView) -> UIView {
  var items: [UIView] = [
    label(header.uppercased(), style: .footnote, color: .secondaryLabel),
    card(contents: contents, radius: 12),
  ]
  if let footer {
    let l = UILabel()
    l.text = footer
    l.font = .preferredFont(forTextStyle: .footnote)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    l.translatesAutoresizingMaskIntoConstraints = false
    items.append(l)
  }
  return vStack(items, spacing: 6)
}

// MARK: - Separator

extension UIView {
  static func separator() -> UIView {
    let v = UIView()
    v.backgroundColor = .separator
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
    return v
  }
}
