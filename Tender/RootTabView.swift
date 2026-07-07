import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            EntryListView()
                .tabItem {
                    Label("Home", systemImage: "banknote.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(TDTheme.brass)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(TDTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(TenderStore())
        .environmentObject(PurchaseManager())
}
