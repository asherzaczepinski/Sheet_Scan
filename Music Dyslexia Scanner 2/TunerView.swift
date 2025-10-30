import AVFoundation
import Accelerate
import Foundation
import SwiftUI
struct DynamicTuningTips {
    enum TuningStatus {
        case flat
        case sharp
    }
    
    enum Note: String, CaseIterable {
        case C, Csharp, Db
        case D, Dsharp, Eb
        case E
        case F, Fsharp, Gb
        case G, Gsharp, Ab
        case A, Asharp, Bb
        case B
        
        // For display purposes
        var displayName: String {
            switch self {
            case .Csharp: return "C#"
            case .Db: return "Db"
            case .Dsharp: return "D#"
            case .Eb: return "Eb"
            case .Fsharp: return "F#"
            case .Gb: return "Gb"
            case .Gsharp: return "G#"
            case .Ab: return "Ab"
            case .Asharp: return "A#"
            case .Bb: return "Bb"
            default: return rawValue
            }
        }
    }
    
    /// Get specific tuning tip for an instrument, note, and tuning status
    static func getTip(instrument: String, note: Note, status: TuningStatus) -> String {
        switch instrument {
        case "Alto Saxophone":
            return altoSaxophoneTips(note: note, status: status)
        case "Bass Clarinet":
            return bassClarinetTips(note: note, status: status)
        case "Bassoon":
            return bassoonTips(note: note, status: status)
        case "Cello":
            return celloTips(note: note, status: status)
        case "Clarinet":
            return clarinetTips(note: note, status: status)
        case "Double Bass":
            return doubleBassTips(note: note, status: status)
        case "Euphonium":
            return euphoniumTips(note: note, status: status)
        case "Flute":
            return fluteTips(note: note, status: status)
        case "French Horn":
            return frenchHornTips(note: note, status: status)
        case "Oboe":
            return oboeTips(note: note, status: status)
        case "Piano":
            return pianoTips(note: note, status: status)
        case "Tenor Saxophone":
            return tenorSaxophoneTips(note: note, status: status)
        case "Trombone":
            return tromboneTips(note: note, status: status)
        case "Trumpet":
            return trumpetTips(note: note, status: status)
        case "Tuba":
            return tubaTips(note: note, status: status)
        case "Viola":
            return violaTips(note: note, status: status)
        case "Violin":
            return violinTips(note: note, status: status)
        default:
            return "Instrument not supported. Please select a supported instrument for specific tuning advice."
        }
    }
    
    // MARK: - Instrument-specific tuning tips
    private static func altoSaxophoneTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSixthUp) // Eb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the mouthpiece further onto the cork. Firm your embouchure."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the mouthpiece away from the cork. Relax your embouchure."
    }
    
    private static func bassClarinetTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp) // Bb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the barrel and upper joint together. Extend the neck if adjustable."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the barrel away from the upper joint. Retract the neck if adjustable."
    }
    
    private static func bassoonTips(note: Note, status: TuningStatus) -> String {
        return status == .flat
            ? "You are flat on \(note.displayName). Push the bocal deeper into the wing joint. Support with firmer air pressure."
            : "You are sharp on \(note.displayName). Pull the bocal slightly out of the wing joint. Use less air pressure."
    }
    
    private static func celloTips(note: Note, status: TuningStatus) -> String {
        let stringInfo = getCelloStringForNote(note)
        return status == .flat
            ? "You are flat on \(note.displayName). Tighten the \(stringInfo.string) string peg clockwise. Use the fine tuner clockwise if available."
            : "You are sharp on \(note.displayName). Loosen the \(stringInfo.string) string peg counterclockwise. Use the fine tuner counterclockwise if available."
    }
    
    private static func clarinetTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp) // Bb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the barrel closer to the upper joint. Firm your embouchure."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the barrel away from the upper joint. Relax your embouchure."
    }
    
    private static func doubleBassTips(note: Note, status: TuningStatus) -> String {
        let stringInfo = getDoubleBassStringForNote(note)
        return status == .flat
            ? "You are flat on \(note.displayName). Tighten the \(stringInfo.string) string using the tuning machine. Use the fine tuner if available."
            : "You are sharp on \(note.displayName). Loosen the \(stringInfo.string) string using the tuning machine. Use the fine tuner if available."
    }
    
    private static func euphoniumTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp) // Bb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the main tuning slide in. Check valve slide positions."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the main tuning slide out. Adjust valve slides as needed."
    }
    
    private static func fluteTips(note: Note, status: TuningStatus) -> String {
        return status == .flat
            ? "You are flat on \(note.displayName). Push the headjoint further into the body. Cover the embouchure hole more and use focused air."
            : "You are sharp on \(note.displayName). Pull the headjoint out slightly. Uncover the embouchure hole slightly and use broader air."
    }
    
    private static func frenchHornTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .perfectFifthDown) // F instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Adjust main tuning slide inward. Use less right hand in bell."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Adjust main tuning slide outward. Use more right hand in bell."
    }
    
    private static func oboeTips(note: Note, status: TuningStatus) -> String {
        return status == .flat
            ? "You are flat on \(note.displayName). Push the reed further onto the staple. Use more focused embouchure and air support."
            : "You are sharp on \(note.displayName). Pull the reed slightly off the staple. Relax embouchure and use less air pressure."
    }
    
    private static func pianoTips(note: Note, status: TuningStatus) -> String {
        return status == .flat
            ? "You are flat on your \(note.displayName). Have a piano technician tune your piano."
            : "You are sharp on your \(note.displayName). Have a piano technician tune your piano."
    }
    
    private static func tenorSaxophoneTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp) // Bb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the mouthpiece further onto the cork. Firm your embouchure."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the mouthpiece away from the cork. Relax your embouchure."
    }
    
    private static func tromboneTips(note: Note, status: TuningStatus) -> String {
        return status == .flat
            ? "You are flat on \(note.displayName). Extend the slide slightly (move outward). Use firmer lip tension and more air support."
            : "You are sharp on \(note.displayName). Retract the slide slightly (move inward). Relax lip tension and use less air pressure."
    }
    
    private static func trumpetTips(note: Note, status: TuningStatus) -> String {
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp) // Bb instrument
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the main tuning slide in. Check individual valve slides."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the main tuning slide out. Adjust valve slides as needed."
    }
    
    private static func tubaTips(note: Note, status: TuningStatus) -> String {
        // Assuming Bb tuba (most common)
        let writtenNote = getWrittenNote(concertNote: note, transposition: .majorSecondUp)
        return status == .flat
            ? "You are flat on your \(writtenNote) (Concert \(note.displayName)). Push the main tuning slide in. Use more air support and firmer embouchure."
            : "You are sharp on your \(writtenNote) (Concert \(note.displayName)). Pull the main tuning slide out. Use less air pressure and relax embouchure."
    }
    
    private static func violaTips(note: Note, status: TuningStatus) -> String {
        let stringInfo = getViolaStringForNote(note)
        return status == .flat
            ? "You are flat on \(note.displayName). Tighten the \(stringInfo.string) string peg clockwise. Use the fine tuner clockwise if available."
            : "You are sharp on \(note.displayName). Loosen the \(stringInfo.string) string peg counterclockwise. Use the fine tuner counterclockwise if available."
    }
    
    private static func violinTips(note: Note, status: TuningStatus) -> String {
        let stringInfo = getViolinStringForNote(note)
        return status == .flat
            ? "You are flat on \(note.displayName). Tighten the \(stringInfo.string) string peg clockwise. Use the fine tuner clockwise if available."
            : "You are sharp on \(note.displayName). Loosen the \(stringInfo.string) string peg counterclockwise. Use the fine tuner counterclockwise if available."
    }
    
    // MARK: - Helper Functions
    
    enum Transposition {
        case perfectFifthDown  // F instruments (French Horn)
        case majorSecondUp     // Bb instruments (Clarinet, Trumpet, Tenor Sax, etc.)
        case majorSixthUp      // Eb instruments (Alto Sax)
    }
    
    private static func getWrittenNote(concertNote: Note, transposition: Transposition) -> String {
        let semitoneShift: Int
        switch transposition {
        case .perfectFifthDown:
            semitoneShift = 7  // F horn: written note is 7 semitones higher
        case .majorSecondUp:
            semitoneShift = 2  // Bb instruments: written note is 2 semitones higher
        case .majorSixthUp:
            semitoneShift = 9  // Eb instruments: written note is 9 semitones higher
        }
        
        let noteOrder: [Note] = [.C, .Csharp, .D, .Dsharp, .E, .F, .Fsharp, .G, .Gsharp, .A, .Asharp, .B]
        guard let currentIndex = noteOrder.firstIndex(of: concertNote) else { return "?" }
        
        let newIndex = (currentIndex + semitoneShift) % 12
        return noteOrder[newIndex].displayName
    }
    
    private static func getViolinStringForNote(_ note: Note) -> (string: String, position: String) {
        // Violin strings: G(3), D(4), A(4), E(5)
        switch note {
        case .G, .Gsharp, .Ab, .A, .Asharp, .Bb, .B, .C, .Csharp, .Db:
            return ("G", "low position")
        case .D, .Dsharp, .Eb, .E, .F, .Fsharp, .Gb:
            return ("D", "low to mid position")
        }
    }
    
    private static func getViolaStringForNote(_ note: Note) -> (string: String, position: String) {
        // Viola strings: C(3), G(3), D(4), A(4)
        switch note {
        case .C, .Csharp, .Db, .D, .Dsharp, .Eb, .E, .F, .Fsharp, .Gb:
            return ("C", "low position")
        case .G, .Gsharp, .Ab, .A, .Asharp, .Bb, .B:
            return ("G", "low to mid position")
        }
    }
    
    private static func getCelloStringForNote(_ note: Note) -> (string: String, position: String) {
        // Cello strings: C(2), G(2), D(3), A(3)
        switch note {
        case .C, .Csharp, .Db, .D, .Dsharp, .Eb, .E, .F, .Fsharp, .Gb:
            return ("C", "low position")
        case .G, .Gsharp, .Ab, .A, .Asharp, .Bb, .B:
            return ("G", "low to mid position")
        }
    }
    
    private static func getDoubleBassStringForNote(_ note: Note) -> (string: String, position: String) {
        // Double bass strings: E(1), A(1), D(2), G(2)
        switch note {
        case .E, .F, .Fsharp, .Gb, .G, .Gsharp, .Ab:
            return ("E", "low position")
        case .A, .Asharp, .Bb, .B, .C, .Csharp, .Db:
            return ("A", "low to mid position")
        case .D, .Dsharp, .Eb:
            return ("D", "low position")
        }
    }
    
    // MARK: - Utility functions
    /// Convert frequency to closest note
    static func frequencyToNote(_ frequency: Float) -> Note {
        // A4 is 440Hz, which is MIDI note 69
        let noteNum = 12 * log2(frequency / 440) + 69
        // Round to nearest note
        let roundedNoteNum = Int(round(noteNum))
        // Convert MIDI note to note name (C, C#, etc.)
        let noteName = roundedNoteNum % 12
        switch noteName {
        case 0: return .C
        case 1: return .Csharp
        case 2: return .D
        case 3: return .Dsharp
        case 4: return .E
        case 5: return .F
        case 6: return .Fsharp
        case 7: return .G
        case 8: return .Gsharp
        case 9: return .A
        case 10: return .Bb
        case 11: return .B
        default: return .A  // Should never happen
        }
    }
}
struct InTuneTips {
    /// Get specific "in tune" message for an instrument and note
    static func getMessage(instrument: String, note: DynamicTuningTips.Note)
        -> String
    {
        switch instrument {
        case "Alto Saxophone":
            return inTuneAltoSaxophone(note: note)
        case "Bass Clarinet":
            return inTuneBassClarinetTips(note: note)
        case "Clarinet":
            return inTuneClarinetTips(note: note)
        case "Euphonium":
            return inTuneEuphoniumTips(note: note)
        case "French Horn":
            return inTuneFrenchHornTips(note: note)
        case "Piano":
            return inTunePianoTips(note: note)
        case "Tenor Saxophone":
            return inTuneTenorSaxophoneTips(note: note)
        case "Trumpet":
            return inTuneTrumpetTips(note: note)
        case "Tuba":
            return inTuneTubaTips(note: note)
        default:
            return "In tune on \(note.displayName)! Keep it up 🎵"
        }
    }
    // MARK: - Instrument-specific in-tune messages
    private static func inTuneAltoSaxophone(note: DynamicTuningTips.Note)
        -> String
    {
        // FIXED: Removed default case as all enum cases are covered
        switch note {
        case .C: return "In tune on your A (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your A# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your B (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your C (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your C# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your D (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your D# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your E (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab: return "In tune on your F (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your F# (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your G (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your G# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneBassClarinetTips(note: DynamicTuningTips.Note)
        -> String
    {
        // FIXED: Removed default case as all enum cases are covered
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneClarinetTips(note: DynamicTuningTips.Note)
        -> String
    {
        // FIXED: Removed default case as all enum cases are covered
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneEuphoniumTips(note: DynamicTuningTips.Note)
        -> String
    {
        // FIXED: Removed default case as all enum cases are covered
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneFrenchHornTips(note: DynamicTuningTips.Note)
        -> String
    {
        switch note {
        case .C: return "In tune on your G (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your G# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your A (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp:
            return "In tune on your Bb (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your B (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your C (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your C# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your D (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your D# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your E (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your F (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your F# (Concert B)! Keep it up 🎵"
        }
    }
    
    private static func inTunePianoTips(note: DynamicTuningTips.Note) -> String {
        return "In tune on \(note.displayName)! Keep it up 🎵"
    }
    
    private static func inTuneTenorSaxophoneTips(note: DynamicTuningTips.Note)
        -> String
    {
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneTrumpetTips(note: DynamicTuningTips.Note)
        -> String
    {
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
    private static func inTuneTubaTips(note: DynamicTuningTips.Note) -> String {
        switch note {
        case .C: return "In tune on your D (Concert C)! Keep it up 🎵"
        case .Csharp, .Db:
            return "In tune on your D# (Concert C#)! Keep it up 🎵"
        case .D: return "In tune on your E (Concert D)! Keep it up 🎵"
        case .Eb, .Dsharp: return "In tune on your F (Concert Eb)! Keep it up 🎵"
        case .E: return "In tune on your F# (Concert E)! Keep it up 🎵"
        case .F: return "In tune on your G (Concert F)! Keep it up 🎵"
        case .Fsharp, .Gb:
            return "In tune on your G# (Concert F#)! Keep it up 🎵"
        case .G: return "In tune on your A (Concert G)! Keep it up 🎵"
        case .Gsharp, .Ab:
            return "In tune on your A# (Concert G#)! Keep it up 🎵"
        case .A: return "In tune on your B (Concert A)! Keep it up 🎵"
        case .Bb, .Asharp: return "In tune on your C (Concert Bb)! Keep it up 🎵"
        case .B: return "In tune on your C# (Concert B)! Keep it up 🎵"
        }
    }
}
// MARK: – Needle View
struct NeedleView: View {
    var detuneCents: Float
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let radius = w / 2
            let center = CGPoint(x: w / 2, y: geo.size.height)
            let bottomY = center.y - radius
            ZStack {
                ForEach(0..<23, id: \.self) { i in
                    let v = Float(i) * 100 / 22 - 50
                    let angle = Angle(degrees: Double(v) / 50 * 60)
                    let dist = abs(v - detuneCents)
                    let width: CGFloat = dist < 2.5 ? 3 : 2
                    let length: CGFloat = {
                        switch dist {
                        case 0..<2.5: return 20
                        case 2.5..<7.5: return 16
                        case 7.5..<12.5: return 13
                        default: return 11
                        }
                    }()
                    let color: Color = {
                        switch v {
                        case -5...5: return .green
                        case -15..<(-5), 6...15: return .yellow
                        default: return .red
                        }
                    }()
                    Rectangle()
                        .fill(color)
                        .frame(width: width, height: length)
                        .offset(y: -radius - length / 2)
                        .rotationEffect(angle)
                        .position(center)
                }
                Text(String(format: "%+.0f¢", detuneCents))
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(centsColor(for: detuneCents))
                    .position(x: w / 2, y: bottomY + 50)
            }
            .offset(y: 70)
        }
    }
    private func centsColor(for cents: Float) -> Color {
        switch cents {
        case -5...5: return .green
        case -15..<(-5), 6...15: return .yellow
        default: return .red
        }
    }
}
// MARK: – Main View
struct TunerView: View {
    @StateObject private var audioMonitor = AudioMonitor()  // Monitor volume
    @State private var hasTriedStarting: Bool = false  // Track if user has tried to start
    @EnvironmentObject var settings: AppSettings
    @StateObject private var tuner = TunerEngine()
    @StateObject private var reference = ReferenceEngine()
    @State private var showingPicker = false
    @State private var showTips = true
    @State private var referenceFrequency: Float = 440
    // Store detected note for tuning tips
    @State private var currentNote: DynamicTuningTips.Note = .A
    // Alert states
    @State private var showVolumeAlert = false
    @State private var alertDismissedManually = false
    // Audio loading overlay states
    @State private var showAudioLoadingOverlay = false
    @State private var longLoadingDetected = false
    // FIXED: Track mic permission status using proper iOS version compatibility
    @State private var micPermission: MicPermissionStatus = .undetermined
    
    // Helper enum to handle different iOS versions
    enum MicPermissionStatus {
        case undetermined
        case denied
        case granted
    }
    
    // Helper function to get current permission status
    // Helper function to get current permission status
    // Helper function to get current permission status
    private func getCurrentMicPermission() -> MicPermissionStatus {
        if #available(iOS 17.0, *) {
            let permission = AVAudioApplication.shared.recordPermission
            if permission == .undetermined {
                return .undetermined
            } else if permission == .denied {
                return .denied
            } else if permission == .granted {
                return .granted
            } else {
                return .undetermined
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                return .undetermined
            case .denied:
                return .denied
            case .granted:
                return .granted
            @unknown default:
                return .undetermined
            }
        }
    }

    // Helper function to request permission
    private func requestMicPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    micPermission = getCurrentMicPermission()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    micPermission = getCurrentMicPermission()
                }
            }
        }
    }
    private let instruments = [
        "Alto Saxophone",
        "Bass Clarinet",
        "Bassoon",
        "Cello",
        "Clarinet",
        "Double Bass",
        "Euphonium",
        "Flute",
        "French Horn",
        "Oboe",
        "Piano",
        "Tenor Saxophone",
        "Trombone",
        "Trumpet",
        "Tuba",
        "Viola",
        "Violin",
    ]
    var body: some View {
        ZStack {
            VStack {
                VStack(spacing: 24) {
                    topControls
                    Toggle("Show Tips:", isOn: $showTips)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if showTips {
                        Text(tipText)
                            .font(.title2).bold()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        Color(UIColor.secondarySystemBackground)
                                    )
                                    .shadow(radius: 1)
                            )
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 10)
            // Add a semi-transparent overlay when alert is showing
            if showVolumeAlert && reference.isPlaying {
                // Semi-transparent background
                Color.black
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: showVolumeAlert && reference.isPlaying
                    )
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
                .zIndex(100)  // Ensure it's above everything including the overlay
                .transition(.opacity)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: showVolumeAlert && reference.isPlaying
                )
            }
        }
        .overlay(
            Group {
                if showAudioLoadingOverlay {
                    // Dimmed background
                    Color.black
                        .opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    // Alert box
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("🔊 Loading Audio…")
                            .font(.headline)
                            .padding(.horizontal)
                        if longLoadingDetected {
                            Text(
                                "Audio is taking too long to load. Please reload the app!"
                            )
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        } else {
                            Text("This may take a moment…")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        // (no OK button here)
                    }
                    .padding(.vertical, 20)  // 8px top & bottom padding
                    
                    .frame(width: 280)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .zIndex(110)
                }
            }
        )
        .overlay(
            Group {
                // FIXED: Use helper enum for microphone permission
                if micPermission == .denied {
                    // Dimmed background
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(120)
                    // Alert box
                    VStack(spacing: 16) {
                        Text("🎤 Microphone Access Required")
                            .font(.headline)
                            .padding(.top, 20)
                        Text("Please enable microphone access in Settings to use tuning features.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .frame(width: 280)
                    .padding(.bottom, 20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .zIndex(121)
                }
            }
        )
        .onAppear {
            // FIXED: Request mic permission using helper functions for version compatibility
            micPermission = getCurrentMicPermission()
            if micPermission == .undetermined {
                requestMicPermission()
            }
            // --- Existing onAppear logic ---
            tuner.start()
            reference.configure(sampleRate: tuner.sampleRate)
            reference.setFrequency(referenceFrequency)
            tuner.referenceHz = referenceFrequency
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkAudioStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabChanged)) {
            notification in
            if let selection = notification.userInfo?["selection"] as? Int,
                selection == 2
            {
                // Check if audio is ready when switching to tuner tab
                checkAudioStatus()
            }
        }
        .onReceive(tuner.$isInterrupted) {
            if $0 { reference.stop() }
        }
        .onReceive(tuner.$detectedFrequency) { frequency in
            // Update current note when frequency changes
            if frequency > 0 {
                currentNote = DynamicTuningTips.frequencyToNote(frequency)
            }
        }
        .onChange(of: tuner.isAudioInitialized) { _, initialized in
            if initialized {
                // Audio is properly initialized, hide the overlay
                showAudioLoadingOverlay = false
                longLoadingDetected = false
            }
        }
        .onDisappear {
            tuner.stop()
            reference.stop()
        }
        .sheet(isPresented: $showingPicker) {
            instrumentPicker
        }
        .onChange(of: audioMonitor.volume) { _, newValue in
            handleVolumeChange(newValue)
        }
        .onChange(of: reference.isPlaying) { _, isPlaying in
            // Immediately hide alert when playback stops
            if !isPlaying {
                showVolumeAlert = false
                // Reset the dismissal flag when playback stops
                alertDismissedManually = false
            } else if audioMonitor.volume < 0.7 && !alertDismissedManually {
                // Show alert when playback starts with low volume
                // but only if user hasn't manually dismissed it
                showVolumeAlert = true
            }
        }
    }
    // MARK: – Tuning Tips Text
    private var tipText: String {
        if !tuner.isAudioDetected {
            return tuner.isActive
                ?
                "Play louder for accurate tuning."
                :
                "Play a note to begin tuning."
        }
        let cents = tuner.detuneCents
        // When in tune, show instrument-specific message
        if abs(cents) <= 5 {
            return InTuneTips.getMessage(
                instrument: settings.selectedInstrument,
                note: currentNote
            )
        } else {
            // Get the tuning status
            let status: DynamicTuningTips.TuningStatus =
                cents < 0 ? .flat : .sharp
            // Get the instrument-specific tip
            let instrumentTip = DynamicTuningTips.getTip(
                instrument: settings.selectedInstrument,
                note: currentNote,
                status: status
            )
            return instrumentTip
        }
    }
    // MARK: – Top Controls
    private var topControls: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Instrument:")
                    .font(.title2)
                Spacer()
                Button(action: { showingPicker = true }) {
                    HStack {
                        Text(settings.selectedInstrument)
                            .font(.title2)
                        Image(systemName: "chevron.down")
                    }
                }
            }
            NeedleView(detuneCents: tuner.isActive ? tuner.detuneCents : 0)
                .frame(height: 125)
                .frame(maxWidth: .infinity)
                .animation(
                    .easeOut(duration: tuner.isActive ? 0.1 : 0.5),
                    value: tuner.detuneCents
                )
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Button {
                        referenceFrequency = max(220, referenceFrequency - 1)
                        updateReference()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                    }
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { Double(referenceFrequency) },
                                set: {
                                    referenceFrequency = Float($0)
                                    updateReference()
                                }
                            ),
                            in: 220...880,
                            step: 1
                        )
                        .padding(.top, 25)
                        .padding(.bottom, 5)
                        Text("\(Int(referenceFrequency)) Hz")
                            .font(.system(size: 18, weight: .regular))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity)
                    Button {
                        referenceFrequency = min(880, referenceFrequency + 1)
                        updateReference()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                    }
                    Button {
                        hasTriedStarting = true  // Mark that user tried to start audio
                        reference.isPlaying
                            ? reference.stop() : reference.start()
                    } label: {
                        Image(
                            systemName: reference.isPlaying
                                ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 40))
                        .foregroundColor(reference.isPlaying ? .red : .green)
                    }
                }
                Divider()
                    .padding(.top, 15)
                    .padding(.bottom, -5)
            }
            .padding(.top, -25)
        }
    }
    // MARK: – Instrument Picker
    private var instrumentPicker: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Choose Instrument")
                .font(.title2)
                .bold()
            Picker("Instrument", selection: $settings.selectedInstrument) {
                ForEach(instruments, id: \.self) {
                    Text($0).font(.title2)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 200)
            .clipped()
            .onChange(of: settings.selectedInstrument) { _, _ in
                UISelectionFeedbackGenerator().selectionChanged()
            }
            Button("Select") {
                showingPicker = false
            }
            .font(.title2)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.accentColor))
            .foregroundColor(.white)
            .padding(.top, 20)
            Spacer()
        }
    }
    // MARK: – Reference Update
    private func updateReference() {
        reference.setFrequency(referenceFrequency)
        tuner.referenceHz = referenceFrequency
    }
    // MARK: – Handle Volume Change
    private func handleVolumeChange(_ vol: Float) {
        if vol >= 0.7 {
            // Volume is now above threshold, reset the manual dismissal flag
            alertDismissedManually = false
            // Also hide the alert if it's currently showing
            showVolumeAlert = false
        } else if vol < 0.7 && !alertDismissedManually && reference.isPlaying {
            // Only show alert if:
            // 1. Volume is low
            // 2. User hasn't manually dismissed it
            // 3. Reference is playing
            showVolumeAlert = true
        }
    }
    // MARK: - Audio Status Check
    private func checkAudioStatus() {
        // Reset state
        longLoadingDetected = false
        // Only show the overlay if the audio isn't initialized yet
        if !tuner.isAudioInitialized {
            showAudioLoadingOverlay = true
            // Make sure tuner is started
            if !tuner.engineIsRunning {
                tuner.start()
            }
            // Start a timer to update the message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if showAudioLoadingOverlay {
                    longLoadingDetected = true
                }
            }
            // Force hide the overlay after 10 seconds even if not initialized
            // This prevents it from being stuck forever
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if showAudioLoadingOverlay {
                    print(
                        "Audio failed to initialize after timeout, hiding overlay"
                    )
                    showAudioLoadingOverlay = false
                }
            }
        }
    }
}
// MARK: - Tuner Engine
class TunerEngine: NSObject, ObservableObject {
    @Published var detuneCents: Float = 0
    @Published var isInterrupted: Bool = false
    @Published var detectedFrequency: Float = 0
    @Published var audioLevel: Float = 0
    @Published var isAudioDetected: Bool = false
    @Published var isActive: Bool = false  // Track if we're actively receiving audio
    @Published var isAudioInitialized: Bool = false  // Track if audio is properly initialized
    var referenceHz: Float = 440
    private(set) var sampleRate: Double = 44_100
    // Volume threshold - adjust based on testing
    private let volumeThreshold: Float = 0.02
    // Timer for resetting to zero
    private var inactivityTimer: Timer?
    private let inactivityTimeout: TimeInterval = 1.0
    private let bufferSize: AVAudioFrameCount = 4096
    private var engine = AVAudioEngine()
    private var _isRunning = false  // Internal tracking variable
    // Public property to check engine status
    var engineIsRunning: Bool {
        return _isRunning
    }
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    deinit {
        inactivityTimer?.invalidate()
        stop()
    }
    func start() {
        // Only start if not already running
        guard !_isRunning && !isInterrupted else { return }
        // Set up the audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                options: [.mixWithOthers, .defaultToSpeaker]
            )
            try session.setMode(.measurement)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        // Set up the engine
        let input = engine.inputNode
        let hwFormat = input.outputFormat(forBus: 0)
        sampleRate = hwFormat.sampleRate
        // Remove any existing tap
        input.removeTap(onBus: 0)
        // Install tap
        input.installTap(onBus: 0, bufferSize: bufferSize, format: hwFormat) {
            [weak self] buffer, _ in
            guard let self = self,
                let data = buffer.floatChannelData?[0]
            else { return }
            let samples = Array(
                UnsafeBufferPointer(
                    start: data,
                    count: Int(buffer.frameLength)
                )
            )
            // Calculate audio level (RMS)
            var sum: Float = 0
            for sample in samples {
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(samples.count))
            DispatchQueue.main.async {
                // As soon as we get any buffer, audio is initialized
                if !self.isAudioInitialized {
                    self.isAudioInitialized = true
                }
                self.audioLevel = rms
                // Only process pitch if volume is above threshold
                if rms > self.volumeThreshold {
                    let freq = self.detectPitch(samples: samples)
                    self.detectedFrequency = freq
                    self.detuneCents = self.calculateCents(
                        freq: freq,
                        reference: self.referenceHz
                    )
                    self.isAudioDetected = true
                    self.isActive = true
                    // Reset and restart the inactivity timer
                    self.resetInactivityTimer()
                } else {
                    self.isAudioDetected = false
                }
            }
        }
        // Start the engine
        do {
            try engine.start()
            _isRunning = true
            // Start the inactivity timer
            resetInactivityTimer()
        } catch {
            print("Failed to start audio engine: \(error)")
            // Clean up if engine fails to start
            cleanup()
        }
    }
    func stop() {
        guard _isRunning else { return }
        cleanup()
    }
    private func cleanup() {
        // Remove tap safely - no need to check, it's safe to call even if no tap exists
        engine.inputNode.removeTap(onBus: 0)
        // Stop engine
        engine.stop()
        // Update state
        _isRunning = false
        isAudioInitialized = false
        // Invalidate timer
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    // Reset the inactivity timer
    private func resetInactivityTimer() {
        // Cancel existing timer
        inactivityTimer?.invalidate()
        // Create new timer
        inactivityTimer = Timer.scheduledTimer(
            withTimeInterval: inactivityTimeout,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            // After timeout, reset the UI if we're not detecting audio
            DispatchQueue.main.async {
                if !self.isAudioDetected {
                    self.detuneCents = 0
                    self.detectedFrequency = 0
                    self.isActive = false
                }
            }
        }
    }
    @objc private func handleAudioSessionInterruption(
        _ notification: Notification
    ) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        switch type {
        case .began:
            isInterrupted = true
            stop()
        case .ended:
            guard
                let optsValue = info[AVAudioSessionInterruptionOptionKey]
                    as? UInt
            else { return }
            let options = AVAudioSession.InterruptionOptions(
                rawValue: optsValue
            )
            if options.contains(.shouldResume) {
                isInterrupted = false
                start()
            }
        @unknown default:
            break
        }
    }
    private func detectPitch(samples: [Float]) -> Float {
        let n = samples.count
        var mean: Float = 0
        vDSP_meanv(samples, 1, &mean, vDSP_Length(n))
        var x = [Float](repeating: 0, count: n)
        vDSP_vsadd(samples, 1, [-mean], &x, 1, vDSP_Length(n))
        let minLag = Int(sampleRate / 880)
        let maxLag = Int(sampleRate / 220)
        var bestLag = minLag
        var maxCorr: Float = -Float.greatestFiniteMagnitude
        x.withUnsafeBufferPointer { bufPtr in
            guard let base = bufPtr.baseAddress else { return }
            for lag in minLag...maxLag {
                var corr: Float = 0
                vDSP_dotpr(
                    base,
                    1,
                    base.advanced(by: lag),
                    1,
                    &corr,
                    vDSP_Length(n - lag)
                )
                if corr > maxCorr {
                    maxCorr = corr
                    bestLag = lag
                }
            }
        }
        var trueLag: Float = Float(bestLag)
        x.withUnsafeBufferPointer { bufPtr in
            guard let base = bufPtr.baseAddress else { return }
            func autocorr(at lag: Int) -> Float {
                guard lag > 0 && lag < n else {
                    return -Float.greatestFiniteMagnitude
                }
                var c: Float = 0
                vDSP_dotpr(
                    base,
                    1,
                    base.advanced(by: lag),
                    1,
                    &c,
                    vDSP_Length(n - lag)
                )
                return c
            }
            let cL = autocorr(at: bestLag - 1)
            let cR = autocorr(at: bestLag + 1)
            let delta = 0.5 * (cL - cR) / (cL - 2 * maxCorr + cR)
            trueLag = Float(bestLag) + Float(delta)
        }
        return Float(sampleRate) / trueLag
    }
    private func calculateCents(freq: Float, reference: Float) -> Float {
        guard freq > 0 && reference > 0 else { return 0 }
        let noteNum = 69 + 12 * log2(freq / reference)
        let nearest = round(noteNum)
        return round((noteNum - nearest) * 100)
    }
}
// MARK: – Reference Engine (unchanged)
class ReferenceEngine: ObservableObject {
    @Published var isPlaying = false
    private var engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var freq: Float = 440
    private var sampleRate: Double = 44_100
    private var phase: Float = 0
    func configure(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
    func setFrequency(_ hz: Float) {
        freq = hz
        if isPlaying { restart() }
    }
    func start() {
        guard !isPlaying else { return }
        createAndAttachNode()
        try? engine.start()
        isPlaying = true
    }
    func stop() {
        guard isPlaying else { return }
        engine.stop()
        if let n = node { engine.detach(n) }
        node = nil
        isPlaying = false
    }
    private func restart() {
        stop()
        start()
    }
    private func createAndAttachNode() {
        phase = 0
        node = AVAudioSourceNode { _, _, frameCount, ablPtr in
            let abl = UnsafeMutableAudioBufferListPointer(ablPtr)
            let inc = 2 * .pi * self.freq / Float(self.sampleRate)
            for frame in 0..<Int(frameCount) {
                let gain: Float = 1.5  // try values from 1.0 up to ~2.0
                let value = sin(self.phase) * gain
                self.phase += inc
                if self.phase >= 2 * .pi { self.phase -= 2 * .pi }
                for buf in abl {
                    buf.mData!.assumingMemoryBound(to: Float.self)[frame] =
                        value
                }
            }
            return noErr
        }
        engine.attach(node!)
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        engine.connect(node!, to: engine.mainMixerNode, format: format)
    }
}
// MARK: – Preview
struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView()
    }
}
