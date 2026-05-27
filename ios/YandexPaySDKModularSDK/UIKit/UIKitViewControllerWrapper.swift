import SwiftUI
import UIKit

struct UIKitWrapper<VC: UIViewController>: UIViewControllerRepresentable {
  let makeVC: () -> VC

  func makeUIViewController(context: Context) -> VC {
    makeVC()
  }

  func updateUIViewController(_ uiViewController: VC, context: Context) {}
}
