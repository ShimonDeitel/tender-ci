import SwiftUI

/// Pro bonus feature: a literal continent-coverage board. Each of the 7
/// continents renders as a stamped rectangle — filled brass/stamp-red and
/// "stamped" with a rotated ink ring once at least one country from that
/// continent has been logged, otherwise a faint outline only. This is the
/// quirky, on-theme reward for going Pro (a customs-passport stamp board).
struct WorldCoverageView: View {
    @EnvironmentObject private var store: TenderStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                TDTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("\(store.coveredContinents.count) of 7 continents stamped")
                                .font(TDTheme.headlineFont)
                                .foregroundStyle(TDTheme.ink)
                            Text("\(store.uniqueCountries.count) unique countries logged")
                                .font(.caption)
                                .foregroundStyle(TDTheme.inkFaded)
                        }
                        .padding(.top, 12)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Continent.allCases) { continent in
                                ContinentStamp(
                                    continent: continent,
                                    covered: store.coveredContinents.contains(continent)
                                )
                                .accessibilityIdentifier("continentStamp_\(continent.rawValue)")
                            }
                        }
                        .padding(.horizontal, 18)

                        if !store.uniqueCountries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Countries Logged")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TDTheme.inkFaded)
                                    .padding(.horizontal, 18)
                                ForEach(store.uniqueCountries, id: \.self) { country in
                                    HStack {
                                        Text(country).foregroundStyle(TDTheme.ink)
                                        Spacer()
                                        let dupes = store.duplicateCountryCount(for: country)
                                        if dupes > 1 {
                                            Text("\(dupes) entries")
                                                .font(.caption)
                                                .foregroundStyle(TDTheme.brass)
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("World Coverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(TDTheme.ink)
                }
            }
        }
    }
}

private struct ContinentStamp: View {
    let continent: Continent
    let covered: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(covered ? TDTheme.surfaceRaised : TDTheme.surface)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(covered ? TDTheme.stampRed : TDTheme.rule, lineWidth: covered ? 3 : 1)

            VStack(spacing: 6) {
                Text(continent.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(covered ? TDTheme.ink : TDTheme.inkFaded)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }

            if covered {
                Text("STAMPED")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(TDTheme.stampRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(TDTheme.stampRed, lineWidth: 1.5))
                    .rotationEffect(.degrees(-12))
                    .opacity(0.9)
            }
        }
        .frame(height: 84)
    }
}

#Preview {
    WorldCoverageView()
        .environmentObject(TenderStore())
}
