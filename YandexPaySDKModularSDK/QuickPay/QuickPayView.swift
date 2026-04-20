import SwiftUI
import UIKit
import YandexQuickPay
import YandexPayConfiguration

struct QuickPayView: View {

  @ObservedObject var viewModel: QuickPayViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        badgeSection
        expandableWidgetSection
        sessionRow
        authSection
        controlsSection
        if let error = viewModel.lastError {
          Text(error)
            .foregroundStyle(.red)
            .font(.caption)
            .padding(.horizontal)
        }
      }
      .padding()
    }
    .navigationTitle("Quick Pay")
    .onAppear {
      viewModel.loadInitialState()
      Task { await viewModel.setupWidgetExpandObserver() }
    }
    .onDisappear {
      viewModel.cleanup()
    }
  }

  private var badgeSection: some View {
    Group {
      if viewModel.isPaymentEnabled, viewModel.badgeIsVisible {
        HStack {
          Spacer()
          AnyView(activeBadge)
            .fixedSize(horizontal: true, vertical: true)
        }
      }
    }
  }

  private var activeBadge: any View {
    YPay.instance.quickPay.createActivePaymentMethodBadge()
  }

  private var expandableWidgetSection: some View {
    AnyView(expandableWidget)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var expandableWidget: any View {
    YPay.instance.quickPay.createExpandablePaymentMethodsWidget(expandState: .collapsed)
  }

  private var sessionRow: some View {
    HStack(spacing: 4) {
      Text("Session:")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(viewModel.sessionId ?? "-")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
      Button {
        UIPasteboard.general.string = viewModel.sessionId ?? ""
      } label: {
        Image(systemName: "doc.on.doc")
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var authSection: some View {
    VStack(spacing: 8) {
      HStack(spacing: 4) {
        Text("Auth State:")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Spacer()
        Text(viewModel.currentAuthState)
          .font(.subheadline.weight(.medium))
          .lineLimit(1)
          .truncationMode(.tail)
      }
      if let result = viewModel.securityCheckResult {
        HStack(spacing: 4) {
          Text("Security Check:")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Text(result)
            .font(.caption.weight(.medium))
        }
      }
      HStack(spacing: 12) {
        Button("Auth State") {
          viewModel.fetchAuthState()
        }
        .buttonStyle(.bordered)

        Button("Security Check") {
          viewModel.fetchSecurityCheckRequired()
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var controlsSection: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Quick Payment Enabled")
        Spacer()
        Toggle(
          "",
          isOn: Binding(
            get: { viewModel.isPaymentEnabled },
            set: { viewModel.toggleQuickPayment($0) }
          )
        )
        .disabled(viewModel.isLoading)
        .labelsHidden()
      }

      HStack {
        Text("Show Badge")
        Spacer()
        Toggle(
          "",
          isOn: Binding(
            get: { viewModel.badgeIsVisible },
            set: { viewModel.toggleBadgeVisibility($0) }
          )
        )
        .disabled(!viewModel.isPaymentEnabled)
        .labelsHidden()
      }

      Divider()

      if viewModel.isLoading {
        ProgressView()
      }

      HStack(spacing: 12) {
        Button("Get Session") {
          Task { await viewModel.getSession() }
        }
        .buttonStyle(.borderedProminent)

        Button("Toggle Widget") {
          viewModel.toggleWidget()
        }
        .buttonStyle(.bordered)
      }

      HStack(spacing: 12) {
        Button("FAQ") {
          Task { await viewModel.showFaqScreen() }
        }
        .buttonStyle(.bordered)

        Button("Onboarding") {
          Task { await viewModel.showOnboardingStoriesScreen() }
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
