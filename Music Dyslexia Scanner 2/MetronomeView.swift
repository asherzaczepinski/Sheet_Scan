import SwiftUI
import Combine
import AVFoundation
import UIKit

// MARK: – ObservableObject to monitor system volume via KVO
class AudioMonitor: ObservableObject {
    @Published var volume: Float = 1.0
    private var observation: NSKeyValueObservation?

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        volume = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            if let v = change.newValue {
                DispatchQueue.main.async { self?.volume = v }
            }
        }
    }

    deinit {
        observation?.invalidate()
    }
}

struct MetronomeView: View {
    // MARK: – Environment & Audio volume monitor
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audioMonitor = AudioMonitor()

    // MARK: – Background Task
    @State private var bgTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: – Metronome State
    @State private var bpm: Double = 100
    @State private var isPlaying: Bool = false
    @State private var currentTick: Int = 0
    @State private var timer: DispatchSourceTimer?
    
    // Modified Volume Alert State
    @State private var showVolumeAlert: Bool = false
    @State private var alertDismissedManually: Bool = false

    // tap-tempo & settings
    @State private var tapTimes: [Double] = []
    @State private var timeSignature: String = "4/4"
    @State private var subdivision: String = "Quarter"
    @State private var stressFirstBeat: Bool = true
    @State private var audioReady: Bool = false

    // MARK: – Static Audio engine & buffers
    private static let engine = AVAudioEngine()
    private static let player = AVAudioPlayerNode()
    private static var normalBuffer: AVAudioPCMBuffer!
    private static var accentBuffer: AVAudioPCMBuffer!

    // MARK: – UI options
    private let timeSignatures = ["2/4","3/4","4/4","6/8"]
    private let subdivisions    = ["Quarter","Eighth","Triplets","Sixteenth"]
    private let minBPM: Double  = 30
    private let maxBPM: Double  = 240

    // MARK: – Computed helpers
    private var timeSignatureComponents: (top: Int,bottom: Int) {
        let parts = timeSignature.split(separator: "/")
        return (Int(parts.first ?? "4") ?? 4, Int(parts.last  ?? "4") ?? 4)
    }
    private var subdivisionSymbols: [String] {
        switch subdivision {
            case "Eighth":    return ["&"]
            case "Triplets":  return ["trip","let"]
            case "Sixteenth": return ["e","+","a"]
            default:           return []
        }
    }
    private var ticksPerMeasure: Int {
        timeSignatureComponents.top * (subdivisionSymbols.isEmpty ? 1 : subdivisionSymbols.count + 1)
    }
    private var groupedBeatPattern: [[String]] {
        let N = timeSignatureComponents.top
        let perBeat = subdivisionSymbols.isEmpty ? 1 : subdivisionSymbols.count + 1
        let maxCols = max(1, 8 / perBeat)
        let rows = Int(ceil(Double(N) / Double(maxCols)))
        var result = [[String]]()
        var idx = 0
        for r in 0..<rows {
            let extra = N % rows
            let size = (N / rows) + (r < extra ? 1 : 0)
            let slice = (idx..<min(idx+size, N)).flatMap { i in ["\(i+1)"] + subdivisionSymbols }
            result.append(slice)
            idx += size
        }
        return result
    }

    var body: some View {
        Group {
            ZStack {
                if !audioReady {
                    ProgressView("Loading Audio (Go to other Sheet Scan tab and come back)…")
                        .onAppear {
                            setupAudioEngine()
                            handleVolumeChange(audioMonitor.volume)
                        }
                } else {
                    mainInterface
                }
                
                // Add a semi-transparent overlay when alert is showing
                if showVolumeAlert && isPlaying {
                    // Semi-transparent background
                    Color.black
                        .opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: showVolumeAlert && isPlaying)
                        .zIndex(90)
                    
                    // Alert
                    VStack(spacing: 16) {
                        Text("🔈 Volume Too Low")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("Please increase your device volume.")
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Immediately dismiss and set flag
                            showVolumeAlert = false
                            alertDismissedManually = true
                        }) {
                            Text("OK")
                                .frame(width: 100, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.bottom)
                    }
                    .frame(width: 280)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .zIndex(100) // Ensure it's above everything including the overlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showVolumeAlert && isPlaying)
                }
            }
            .onAppear {
                handleVolumeChange(audioMonitor.volume)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    handleVolumeChange(audioMonitor.volume)
                }
            }
            .onChange(of: audioMonitor.volume) { _, newValue in
                handleVolumeChange(newValue)
            }
            .onChange(of: isPlaying) { _, isPlaying in
                // Immediately hide alert when playback stops
                if !isPlaying {
                    showVolumeAlert = false
                    // Reset the dismissal flag when playback stops
                    alertDismissedManually = false
                } else if audioMonitor.volume < 0.7 && !alertDismissedManually {
                    // Show alert when playback starts with low volume
                    // but only if user hasn't dismissed it manually
                    showVolumeAlert = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notif in
                handleInterruption(notif)
            }
            // Listen for tab changes and stop the metronome if user leaves tab 1
            .onReceive(NotificationCenter.default.publisher(for: .tabChanged)) { note in
                let newTab = note.userInfo?["selection"] as? Int ?? 0
                if newTab != 1 && isPlaying {
                    // Wait just long enough to let the UI switch tabs first (visually)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        stopMetronome()
                    }
                }
            }
        }
    }

    // MARK: – Main Interface
    private var mainInterface: some View {
        VStack(spacing:20) {
            bpmControl
            tapTempoButton
            if !tapTimes.isEmpty {
                tapCirclesView
            } else {
                settingsPickers
                playStopButton
            }
            Spacer()
        }
        .padding()
    }

    // MARK: – BPM Control
    private var bpmControl: some View {
        VStack(spacing:5) {
            Text("\(Int(bpm)) BPM").font(.largeTitle)
            HStack {
                Button {
                    bpm = max(bpm - 1, minBPM)
                    if isPlaying { restartMetronome() }
                } label: {
                    Text("-").font(.largeTitle)
                        .frame(width:60, height:60)
                        .background(tapTimes.isEmpty ? Color.gray.opacity(0.2) : Color.gray.opacity(0.5))
                        .cornerRadius(30)
                }
                .disabled(!tapTimes.isEmpty)

                Slider(value: $bpm, in: minBPM...maxBPM, step: 1)
                    .tint(tapTimes.isEmpty ? .blue : .gray)
                    .padding(.horizontal)
                    .disabled(!tapTimes.isEmpty)
                    .onChange(of: bpm) { _, _ in
                        if isPlaying { restartMetronome() }
                    }

                Button {
                    bpm = min(bpm + 1, maxBPM)
                    if isPlaying { restartMetronome() }
                } label: {
                    Text("+").font(.largeTitle)
                        .frame(width:60, height:60)
                        .background(tapTimes.isEmpty ? Color.gray.opacity(0.2) : Color.gray.opacity(0.5))
                        .cornerRadius(30)
                }
                .disabled(!tapTimes.isEmpty)
            }
        }
    }

    // MARK: – Tap Tempo Button
    private var tapTempoButton: some View {
        Button(action: handleTapTempo) {
            Text("Tap Tempo").font(.title2)
                .frame(maxWidth: .infinity).padding()
                .background(Color(red: 53/255, green: 199/255, blue: 255/255))
                .foregroundColor(.white).cornerRadius(10)
        }
        .padding(.horizontal, 10)
    }

    // MARK: – Tap Circles View
    private var tapCirclesView: some View {
        VStack(spacing:30) {
            HStack(spacing:15) {
                ForEach(0..<timeSignatureComponents.top, id: \.self) { i in
                    if i < tapTimes.count {
                        Circle().frame(width:30, height:30).foregroundColor(.blue)
                    } else {
                        Circle().stroke(Color.gray, lineWidth:2).frame(width:30, height:30)
                    }
                }
            }
            Text("*Keep tapping until all circles fill to set the tempo*")
                .font(.headline).foregroundColor(.gray)
                .multilineTextAlignment(.center).padding(.horizontal,20)
        }
        .padding(.top,20)
    }

    // MARK: – Settings Pickers
    private var settingsPickers: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Signature").font(.headline)
                Picker("", selection: $timeSignature) {
                    ForEach(timeSignatures, id: \.self) { Text($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: timeSignature) { _, _ in
                    if isPlaying { restartMetronome() }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Subdivision").font(.headline)
                Picker("", selection: $subdivision) {
                    ForEach(subdivisions, id: \.self) { Text($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: subdivision) { _, _ in
                    if isPlaying { restartMetronome() }
                }
            }

            HStack {
                Text("Emphasize First Beat").font(.headline)
                Spacer()
                Toggle("", isOn: $stressFirstBeat).labelsHidden()
            }

            beatPatternView
        }
        .padding(.horizontal, 10)
    }

    // MARK: – Beat Pattern View
    private var beatPatternView: some View {
        VStack(spacing:10) {
            ForEach(groupedBeatPattern.indices, id: \.self) { rowIndex in
                GeometryReader { geo in
                    let row = groupedBeatPattern[rowIndex]
                    let count = CGFloat(row.count)
                    let spacing: CGFloat = 10
                    let boxWidth = (geo.size.width - spacing*(count-1)) / count
                    HStack(spacing: spacing) {
                        ForEach(row.indices, id: \.self) { idx in
                            let global = groupedBeatPattern[..<rowIndex].reduce(0) { $0 + $1.count } + idx
                            Text(row[idx])
                                .font(.system(size: subdivisionSymbols.isEmpty ? 16 : 14))
                                .frame(width: boxWidth, height: 40)
                                .background(global == currentTick % ticksPerMeasure ? Color.blue : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(height: 40)
            }
        }
    }

    // MARK: – Play/Stop Button
    private var playStopButton: some View {
        VStack(spacing:8) {
            Button(action: { isPlaying ? stopMetronome() : startMetronome() }) {
                Text(isPlaying ? "Stop" : "Start")
                    .font(.title2)
                    .frame(maxWidth: .infinity).padding()
                    .background(isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white).cornerRadius(10)
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: – Tap Tempo Handler
    private func handleTapTempo() {
        if tapTimes.isEmpty {
            setupAudioEngine()
        }
        if isPlaying { stopMetronome() }

        let now = Date().timeIntervalSince1970 * 1000
        tapTimes.append(now)

        let buffer: AVAudioPCMBuffer = (tapTimes.count == 1) ? MetronomeView.accentBuffer! : MetronomeView.normalBuffer!
        if !MetronomeView.player.isPlaying { MetronomeView.player.play() }
        MetronomeView.player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)

        if tapTimes.count == timeSignatureComponents.top {
            if tapTimes.count > 1 {
                let intervals = zip(tapTimes.dropFirst(), tapTimes).map(-)
                let avg = intervals.reduce(0,+) / Double(intervals.count)
                bpm = min(max(60000 / avg, minBPM), maxBPM)
            }
            tapTimes.removeAll()
            let clickDur = Double(buffer.frameLength) / buffer.format.sampleRate
            DispatchQueue.main.asyncAfter(deadline: .now() + clickDur) { startMetronome() }
        }
    }

    // MARK: – Metronome Logic
    func startMetronome() {
        setupAudioEngine()
        isPlaying = true
        if !Self.player.isPlaying { Self.player.play() }
        tickSound()
        startTimer()
        beginBackgroundTask()
    }

    func stopMetronome() {
        isPlaying = false
        stopTimer()
        Self.player.stop()
        endBackgroundTask()
        currentTick = 0
    }

    func restartMetronome() {
        stopMetronome()
        startMetronome()
    }

    // MARK: – Background Task Handling
    private func beginBackgroundTask() {
        endBackgroundTask()
        bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "Metronome") {
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
    }

    private func endBackgroundTask() {
        if bgTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
    }

    // MARK: – Timer
    private func startTimer() {
        stopTimer()
        let bottom = Double(timeSignatureComponents.bottom)
        let beatDur = (60.0 / bpm) * (4.0 / bottom)
        let multiplier = subdivisionSymbols.isEmpty ? 1.0 : Double(subdivisionSymbols.count + 1)
        let interval = beatDur / multiplier
        let t = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        t.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler {
            DispatchQueue.main.async {
                currentTick = (currentTick + 1) % ticksPerMeasure
                tickSound()
            }
        }
        t.resume()
        timer = t
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tickSound() {
        let buf = (stressFirstBeat && currentTick == 0) ? Self.accentBuffer! : Self.normalBuffer!
        Self.player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    // MARK: – Volume Handling
    private func handleVolumeChange(_ vol: Float) {
        // Set the player volume
        MetronomeView.player.volume = vol
        
        // Check volume conditions only if the metronome is playing
        if isPlaying {
            if vol >= 0.7 {
                // Volume is now above threshold, reset the manual dismissal flag
                alertDismissedManually = false
                
                // Also hide the alert if it's currently showing
                showVolumeAlert = false
            } else if vol < 0.7 && !alertDismissedManually {
                // Only show alert if:
                // 1. Volume is low
                // 2. User hasn't manually dismissed it
                // 3. Metronome is playing
                showVolumeAlert = true
            }
        }
    }

    // MARK: – Audio Setup
    private func setupAudioEngine() {
        Self.engine.stop()
        Self.engine.reset()
        Self.engine.detach(Self.player)

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)

        Self.engine.attach(Self.player)
        let format = Self.engine.mainMixerNode.outputFormat(forBus: 0)
        Self.engine.connect(Self.player, to: Self.engine.mainMixerNode, format: format)

        let rate = format.sampleRate
        let dur: Double = 0.002
        let frames = AVAudioFrameCount(rate * dur)
        func make(freq: Float) -> AVAudioPCMBuffer {
            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
            buf.frameLength = frames
            let ω = 2 * Float.pi * freq / Float(rate)
            for ch in 0..<Int(format.channelCount) {
                let ptr = buf.floatChannelData![ch]
                for i in 0..<Int(frames) {
                    ptr[i] = sin(ω * Float(i))
                }
            }
            return buf
        }
        Self.normalBuffer = make(freq: 1250)
        Self.accentBuffer = make(freq: 3000)

        do {
            try Self.engine.start()
            MetronomeView.player.volume = audioMonitor.volume
            audioReady = true
        } catch {
            print("🔊 Audio engine start failed:", error)
            audioReady = false
        }
    }

    // MARK: – Interruption Handling
    private func handleInterruption(_ n: Notification) {
        guard let info = n.userInfo,
              let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
        else { return }

        switch type {
        case .began:
            stopMetronome()
        case .ended:
            try? AVAudioSession.sharedInstance().setActive(true)
            if isPlaying { startMetronome() }
        @unknown default: break
        }
    }
}

struct MetronomeView_Previews: PreviewProvider {
    static var previews: some View {
        MetronomeView()
    }
}
