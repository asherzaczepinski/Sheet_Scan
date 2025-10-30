import SwiftUI

extension Notification.Name {
    static let tabChanged = Notification.Name("MainTabViewTabChanged")
}

struct MainTabView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            ScannerView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "doc.text.image")
                        Text("Scanner")
                    }
                }
                .tag(0)

            MetronomeView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "timer")
                        Text("Metronome")
                    }
                }
                .tag(1)

            TunerView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "guitars")
                        Text("Tuner")
                    }
                }
                .tag(2)

            ScalesView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "music.note.list")
                        Text("Scales")
                    }
                }
                .tag(3)
        }
        .onChange(of: selection) { oldValue, newValue in
            print("🔄 Tab changed to: \(newValue)")
            
            NotificationCenter.default.post(
                name: .tabChanged,
                object: nil,
                userInfo: ["selection": newValue]
            )
        }
    }
}
