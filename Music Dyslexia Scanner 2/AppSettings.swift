import SwiftUI

// MARK: - AppSettings
// AppSettings with @AppStorage automatically saves all values
final class AppSettings: ObservableObject {
    // Persists all settings across launches via UserDefaults
    @AppStorage("selectedInstrument") var selectedInstrument: String = "Clarinet"
    @AppStorage("selectedOctaves") var selectedOctaves: Int = 2
    @AppStorage("selectedPattern") var selectedPattern: String = "Circle of Fifths"
    @AppStorage("includeFingerings") var includeFingerings: Bool = false
}
