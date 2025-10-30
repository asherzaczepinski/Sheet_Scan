import SwiftUI

struct InstrumentSelectView: View {
    @State private var selectedInstrument = "Trumpet"

    private let instruments = [
        "Alto Saxophone", "Baritone Saxophone", "Bass Clarinet", "Bassoon",
        "Cello", "Clarinet", "Double Bass", "Euphonium (Bass Clef)",
        "Euphonium (Treble Clef)", "Flute", "French Horn", "Harp", "Oboe",
        "Piano", "Tenor Saxophone", "Trombone", "Trumpet", "Tuba",
        "Viola", "Violin"
    ].sorted()

    var body: some View {
        VStack(spacing: 0) {
            Text("Choose Instrument")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Picker(selection: $selectedInstrument, label: Text("")) {
                ForEach(instruments, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()

            Text("Selected: \(selectedInstrument)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Spacer()
        }
        .padding()
    }
}
