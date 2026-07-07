import SwiftUI

/// Tender's identity: navy passport-cover backdrop, brass-coin accent, and a
/// muted stamp-red for highlights — a travel/customs-desk feel. Deliberately
/// distinct from every sibling palette (teal/coral Ticker, bubblegum/mint
/// Coinjar, aqua/moss Rootling, cream/ink-navy "editorial" apps, charcoal/
/// volt-yellow Volt).
enum TDTheme {
    static let backdrop = Color(red: 0.075, green: 0.106, blue: 0.161)     // deep passport navy
    static let surface = Color(red: 0.114, green: 0.153, blue: 0.212)
    static let surfaceRaised = Color(red: 0.153, green: 0.196, blue: 0.263)
    static let ink = Color(red: 0.965, green: 0.953, blue: 0.914)          // warm parchment white
    static let inkFaded = Color(red: 0.965, green: 0.953, blue: 0.914).opacity(0.56)
    static let rule = Color.white.opacity(0.10)

    static let brass = Color(red: 0.784, green: 0.635, blue: 0.318)        // brass-coin accent
    static let brassBright = Color(red: 0.902, green: 0.745, blue: 0.400)
    static let stampRed = Color(red: 0.718, green: 0.271, blue: 0.243)     // customs-stamp red
    static let stampRedBright = Color(red: 0.816, green: 0.337, blue: 0.290)
    static let danger = Color(red: 0.780, green: 0.298, blue: 0.263)
    static let success = Color(red: 0.427, green: 0.635, blue: 0.443)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let displayFont = Font.system(size: 44, weight: .bold, design: .rounded)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
