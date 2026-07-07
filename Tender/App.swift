import SwiftUI

@main
struct TenderApp: App {
    @StateObject private var store = TenderStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("tender_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.dark)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
