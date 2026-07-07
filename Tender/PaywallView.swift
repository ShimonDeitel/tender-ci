import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ZStack {
                TDTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(TDTheme.brass)
                        .padding(.top, 40)

                    Text("Tender Pro")
                        .font(TDTheme.titleFont)
                        .foregroundStyle(TDTheme.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("infinity", "Unlimited logged coins & bills")
                        featureRow("globe.americas.fill", "World continent coverage stamp board")
                        featureRow("banknote.fill", "Total collection value in USD")
                        featureRow("sparkles", "Support future updates")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        purchasing = true
                        Task {
                            await purchases.purchase()
                            purchasing = false
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        HStack {
                            if purchasing {
                                ProgressView().tint(TDTheme.backdrop)
                            } else {
                                Text(purchases.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(TDTheme.brass)
                        .foregroundStyle(TDTheme.backdrop)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(purchasing || purchases.product == nil)
                    .padding(.horizontal, 24)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(.footnote)
                    .foregroundStyle(TDTheme.inkFaded)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(TDTheme.ink)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(TDTheme.brass)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(TDTheme.ink)
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
