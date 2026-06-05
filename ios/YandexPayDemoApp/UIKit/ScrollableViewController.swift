import UIKit

class ScrollableViewController: UIViewController {

  let scrollView: UIScrollView = {
    let s = UIScrollView()
    s.translatesAutoresizingMaskIntoConstraints = false
    return s
  }()

  /// Embeds `content` inside a full-screen scroll view pinned to the view's safe area.
  /// `content` is constrained to the content view's layout margins guide horizontally.
  func installContent(_ content: UIView, topPadding: CGFloat = 16, bottomPadding: CGFloat = 16) {
    content.translatesAutoresizingMaskIntoConstraints = false

    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(content)
    scrollView.addSubview(contentView)
    view.addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

      content.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding),
      content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPadding),
      content.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
    ])
  }

  func addKeyboardDismissGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }
}
