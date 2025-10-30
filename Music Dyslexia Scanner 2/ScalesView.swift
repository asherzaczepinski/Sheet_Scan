import SwiftUI
import MessageUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Mail & Share Wrappers
struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentation
    let recipients: [String]
    let subject: String
    let body: String
    let attachmentData: Data
    let attachmentMimeType: String
    let attachmentFileName: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        init(_ parent: MailView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            parent.presentation.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { .init(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.addAttachmentData(attachmentData,
                             mimeType: attachmentMimeType,
                             fileName: attachmentFileName)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: Context) {}
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {}
}

// MARK: - Document Picker
struct DocumentPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentation
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}


// MARK: - Scale Settings View
struct ScaleSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.presentationMode) private var presentation
    @State private var showingPicker = false

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
        "Tenor Saxophone",
        "Trombone",
        "Trumpet",
        "Tuba",
        "Viola",
        "Violin"
    ]
    
    // MARK: – Dynamic Octave Options w/ Labels
    private var octaveOptions: [(value: Int, label: String)] {
        switch settings.selectedInstrument {
        case "Alto Saxophone", "Bassoon", "Cello", "Viola", "Violin",
             "Euphonium", "French Horn", "Oboe", "Tenor Saxophone",
             "Trombone", "Trumpet":
            return [
                (1, "1"),
                (2, "2")
            ]

        case "Bass Clarinet", "Clarinet":
            return [
                (1, "1"),
                (2, "2"),
                (3, "3 (E, F, F#, G)")
            ]

        case "Double Bass":
            return [
                (1, "1"),
                (2, "2 (A, F, G)")
            ]

        case "Flute":
            return [
                (1, "1"),
                (2, "2"),
                (3, "3 (C)")
            ]

        case "Tuba":
            return [
                (1, "1"),
                (2, "2")
            ]

        default:
            return [
                (1, "1"),
                (2, "2")
            ]
        }
    }
    
    private let patterns = ["Circle of Fifths", "Easy to Hard"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Instrument Selector Row
                    HStack {
                        Text("Instrument:")
                            .font(.title2)
                        Spacer()
                        Button(action: { showingPicker = true }) {
                            HStack(spacing: 4) {
                                Text(settings.selectedInstrument)
                                    .font(.title2)
                                Image(systemName: "chevron.down")
                            }
                        }
                    }

                    // Octaves - now directly binds to settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Octaves")
                            .font(.title2)
                        Picker("Octaves", selection: $settings.selectedOctaves) {
                            ForEach(octaveOptions, id: \.value) { option in
                                Text(option.label)
                                    .font(.title2)
                                    .tag(option.value)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Pattern - now directly binds to settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scale Pattern")
                            .font(.title2)
                        Picker("Pattern", selection: $settings.selectedPattern) {
                            ForEach(patterns, id: \.self) {
                                Text($0).font(.title2)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Fingerings Toggle - now directly binds to settings
                    Toggle("Include Fingerings", isOn: $settings.includeFingerings)
                        .font(.title2)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .padding(.top, 6)
                }
                .padding()
            }
            .navigationTitle("Scale Settings")
            .navigationBarItems(
                leading: Button("Cancel") { presentation.wrappedValue.dismiss() },
                trailing: Button("Done")   { presentation.wrappedValue.dismiss() }
            )
        }
        .sheet(isPresented: $showingPicker) {
            VStack(spacing: 0) {
                Spacer()
                Text("Choose Instrument")
                    .font(.title2).bold()
                Picker("Instrument", selection: $settings.selectedInstrument) {
                    ForEach(instruments, id: \.self) {
                        Text($0).font(.title2)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                .clipped()
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
    }
}
// MARK: - Scales View
struct ScalesView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var pageIndex = 1
    @State private var showSettings = false // Start as false, will auto-open with delay
    @State private var hasAutoOpened = false // Track if we've already auto-opened
    @State private var scalePages = 0
    @State private var fingeringPages = 0
    @State private var needsPageRecalculation = true
    @State private var isExporting = false
    @State private var showingPianoPicker = false // For piano instrument picker
    
    // This model represents a page that can be either a scale or fingering
    struct PageInfo: Identifiable {
        var id: Int
        var isFingeringPage: Bool
        var imageName: String
        
        init(id: Int, isFingeringPage: Bool, imageName: String) {
            self.id = id
            self.isFingeringPage = isFingeringPage
            self.imageName = imageName
        }
    }
    
    // All pages to display (scales + fingerings)
    @State private var allPages: [PageInfo] = []
    
    // Instrument list for piano picker
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
        "Violin"
    ]
    
    // Determine if the current instrument is a string instrument
    private var isStringInstrument: Bool {
        let stringInstruments = ["Viola", "Violin", "Cello", "Double Bass"]
        return stringInstruments.contains(settings.selectedInstrument)
    }
    
    // Generate base path used for scales
    private func getBasePath() -> String {
        var instrumentName = settings.selectedInstrument.lowercased()
        
        // For scales, keep "double bass" as "double_bass" (no special case)
        // Replace spaces with underscores for all instruments
        instrumentName = instrumentName.replacingOccurrences(of: " ", with: "_")
        
        // Determine the pattern suffix
        let patternSuffix = settings.selectedPattern == "Circle of Fifths" ? "-5th" : ""
        
        // Return the base path format
        return "\(instrumentName)\(settings.selectedOctaves)\(patternSuffix)"
    }
    
    private var pdfFileName: String {
        let base = settings.selectedInstrument.replacingOccurrences(of: " ", with: "_")
        // Use "1_octave" (singular) for 1 octave, and "X_octaves" (plural) for more than 1 octave
        let oct = settings.selectedOctaves == 1 ? "1_octave" : "\(settings.selectedOctaves)_octaves"
        let suf = settings.selectedPattern == "Easy to Hard" ? "combined2" : "combined"
        
        return "\(base)_\(oct)_\(suf)"
    }
    
    private var pdfData: Data {
        // If we have fingerings, we need to generate a combined PDF with both scales and fingerings
        if settings.includeFingerings && fingeringPages > 0 {
            // This would require PDF generation code, which is beyond the scope
            // For now, just return the scale PDF data
            guard let url = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf"),
                  let data = try? Data(contentsOf: url) else { return Data() }
            return data
        } else {
            // Just return scales PDF
            guard let url = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf"),
                  let data = try? Data(contentsOf: url) else { return Data() }
            return data
        }
    }
    
    // MARK: - TabBar Appearance Reset Function
    private func resetTabBarAppearance() {
        DispatchQueue.main.async {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.shadowColor = nil
            appearance.shadowImage = UIImage()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().shadowImage = UIImage()
            UITabBar.appearance().backgroundImage = UIImage()
            
            // Force update all existing tab bars
            for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
                for view in window.subviews {
                    if let tabBar = view as? UITabBar {
                        tabBar.standardAppearance = appearance
                        tabBar.scrollEdgeAppearance = appearance
                        tabBar.setNeedsLayout()
                    }
                }
            }
        }
    }
    
    // Find scale pages in the bundle - flattened structure (all files in root)
    private func calculateScalePages() -> Int {
        let maxPagesToCheck = 20
        let basePath = getBasePath()
        
        for i in 1...maxPagesToCheck {
            let imageName = "normal_\(basePath)_\(i)"
            if UIImage(named: imageName) == nil {
                return i - 1
            }
        }
        
        return maxPagesToCheck
    }
    
    // Generate the fingering chart path for string instruments (ORIGINAL LOGIC)
    private func getStringFingeringPath(pageNumber: Int) -> String {
        // For string instruments, we have special path formats
        var instrumentName = settings.selectedInstrument.lowercased()
        
        // Special case for Double Bass - search for "bass"
        if instrumentName == "double bass" {
            instrumentName = "bass"
        }
        
        // Determine the pattern suffix
        let patternSuffix = settings.selectedPattern == "Circle of Fifths" ? "-5th" : ""
        
        // Create the path in Fingerings/ folder (no normal_ prefix)
        return "\(instrumentName)\(settings.selectedOctaves)\(patternSuffix)_\(pageNumber)"
    }
    
    // Better fingering detection for all instruments - flattened structure
    private func calculateFingeringPages() -> Int {
        if !settings.includeFingerings {
            return 0
        }
        
        let maxPagesToCheck = 10
        
        if isStringInstrument {
            // String instruments: check for specific patterns
            for i in 1...maxPagesToCheck {
                let basePath = getStringFingeringPath(pageNumber: i)
                
                // Flattened structure - all files in root
                if UIImage(named: basePath) == nil {
                    print("String instrument: No image found at index \(i). Tried path: \(basePath)")
                    return i - 1
                }
            }
            return maxPagesToCheck
        } else {
            // Non-string instruments: flattened structure
            let instrumentName = settings.selectedInstrument.replacingOccurrences(of: " ", with: "_")
            
            for i in 1...maxPagesToCheck {
                // Try different naming variations for orchestra instruments
                let possiblePaths = [
                    "\(instrumentName)_\(i)",                    // "French_Horn_1"
                    "\(instrumentName.lowercased())_\(i)",      // "french_horn_1"
                ]
                
                // Check if any path exists
                let pathExists = possiblePaths.contains { path in
                    UIImage(named: path) != nil
                }
                
                if !pathExists {
                    print("Orchestra instrument: No image found at index \(i). Tried paths: \(possiblePaths)")
                    return i - 1
                }
            }
            return maxPagesToCheck
        }
    }
    
    // Calculate all pages and build the page model array - flattened structure
    private func calculateAllPages() {
        scalePages = calculateScalePages()
        fingeringPages = calculateFingeringPages()
        
        var pages: [PageInfo] = []
        
        // For string instruments with fingerings enabled
        if isStringInstrument && settings.includeFingerings {
            // Check if we actually found any fingering pages
            if fingeringPages > 0 {
                // For string instruments, use the special path format and REPLACE scales
                for i in 1...fingeringPages {
                    let basePath = getStringFingeringPath(pageNumber: i)
                    
                    pages.append(PageInfo(
                        id: i,
                        isFingeringPage: true,
                        imageName: basePath
                    ))
                }
            } else {
                // No fingering pages found - leave pages empty to trigger error display
            }
        } else {
            // For non-string instruments or when fingerings are disabled:
            
            // First add all scale pages - flattened structure
            if scalePages > 0 {
                let basePath = getBasePath()
                for i in 1...scalePages {
                    pages.append(PageInfo(
                        id: i,
                        isFingeringPage: false,
                        imageName: "normal_\(basePath)_\(i)"
                    ))
                }
            }
            
            // Then add fingering pages if enabled (for non-string instruments)
            if settings.includeFingerings && fingeringPages > 0 && !isStringInstrument {
                let instrumentName = settings.selectedInstrument.replacingOccurrences(of: " ", with: "_")
                
                for i in 1...fingeringPages {
                    // Try naming variations and use the first one that exists
                    let possiblePaths = [
                        "\(instrumentName)_\(i)",                    // "French_Horn_1"
                        "\(instrumentName.lowercased())_\(i)",      // "french_horn_1"
                    ]
                    
                    // Find the first path that exists
                    var finalPath = possiblePaths[0] // Default
                    for path in possiblePaths {
                        if UIImage(named: path) != nil {
                            finalPath = path
                            break
                        }
                    }
                    
                    pages.append(PageInfo(
                        id: scalePages + i,
                        isFingeringPage: true,
                        imageName: finalPath
                    ))
                }
            }
        }
        
        allPages = pages
        
        // Reset page index if it's beyond the available pages
        if !allPages.isEmpty && pageIndex > allPages.count {
            pageIndex = 1
        }
    }
    
    // Get image for a specific page
    private func imageForPage(_ page: PageInfo) -> UIImage? {
        return UIImage(named: page.imageName)
    }
    
    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 16
            let width = geo.size.width - pad * 2
            
            ZStack {
                // 🎯 Add explicit background to prevent transparency issues
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // Check if Piano is selected - show overlay
                if settings.selectedInstrument == "Piano" {
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("Piano not yet supported for scales.")
                                .font(.title2)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Text("Change Instrument:")
                                    .font(.title2)
                                Spacer()
                                Button(action: { showingPianoPicker = true }) {
                                    HStack(spacing: 4) {
                                        Text(settings.selectedInstrument)
                                            .font(.title2)
                                        Image(systemName: "chevron.down")
                                    }
                                }
                            }
                            .frame(width: nil)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        
                        Spacer()
                    }
                    .frame(width: width)
                    .background(Color(UIColor.systemBackground))
                    .padding(.horizontal, pad)
                } else {
                    // Normal view for non-Piano instruments
                    VStack(spacing: 20) {
                        HStack {
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        
                        if !allPages.isEmpty {
                            TabView(selection: $pageIndex) {
                                ForEach(allPages) { page in
                                    Group {
                                        if let img = imageForPage(page) {
                                            // Removed unused ratio variable - was causing warning
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: width)
                                                .clipped()
                                        } else {
                                            // Placeholder for missing images
                                            VStack(spacing: 16) {
                                                Image(systemName: "photo.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.gray)
                                                Text("Image not found")
                                                    .font(.title3)
                                                Text(page.imageName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: width, height: width * 1.4)
                                            .background(Color(UIColor.systemBackground))
                                        }
                                    }
                                    .tag(page.id)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(width: width, height: geo.size.height * 0.7)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedCorner(radius: 12, corners: .allCorners))
                            .overlay(RoundedCorner(radius: 12, corners: .allCorners)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
                            // Only show page indicators if there are multiple pages
                            if allPages.count > 1 {
                                HStack(spacing: 16) {
                                    ForEach(allPages) { page in
                                        Circle()
                                            .fill(page.id == pageIndex ? Color.accentColor : Color.gray.opacity(0.4))
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }
                            
                            Button(action: {
                                // Set loading state
                                isExporting = true
                                
                                // Create temporary URL for the file
                                let documentsDirectory = FileManager.default.temporaryDirectory
                                let fileURL = documentsDirectory.appendingPathComponent(pdfFileName + ".pdf")
                                
                                // Save the file
                                do {
                                    try pdfData.write(to: fileURL)
                                    
                                    // Slight delay for better UX
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        // Open the share sheet
                                        let items: [Any] = [fileURL]
                                        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                                        
                                        // Handler for when sharing sheet is dismissed
                                        activityVC.completionWithItemsHandler = { (_, _, _, _) in
                                            // Reset loading state
                                            DispatchQueue.main.async {
                                                isExporting = false
                                            }
                                        }
                                        
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first,
                                           let rootVC = window.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }
                                } catch {
                                    print("Error saving PDF: \(error)")
                                    isExporting = false
                                }
                            }) {
                                Text(isExporting ? "" : "Save PDF").font(.title3)
                            }
                            .buttonStyle(PrimaryButtonStyle(isLoading: isExporting))
                            .frame(width: width)
                            .disabled(isExporting)
                        } else {
                            // Display a message when no pages are found
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                
                                if settings.includeFingerings && isStringInstrument && fingeringPages == 0 {
                                    // String instrument with fingerings enabled but no fingering charts found
                                    Text("No fingering charts found")
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    let basePath = getStringFingeringPath(pageNumber: 1)
                                    
                                    Text("Looking for fingerings at:\n• \(basePath)")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    Text("Try changing octaves or scale pattern in settings")
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                } else if settings.includeFingerings && scalePages == 0 && fingeringPages == 0 {
                                    // No scales and no fingering charts found
                                    Text("No scales or fingering charts found")
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    if isStringInstrument {
                                        let path = getStringFingeringPath(pageNumber: 1)
                                        let basePath = getBasePath()
                                        Text("Looking for:\n• Scales: normal_\(basePath)_1\n• Fingerings: \(path)")
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    } else {
                                        let instrumentName = settings.selectedInstrument.replacingOccurrences(of: " ", with: "_")
                                        let basePath = getBasePath()
                                        Text("Looking for:\n• Scales: normal_\(basePath)_1\n• Fingerings: \(instrumentName)_1")
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                                } else if settings.includeFingerings && fingeringPages == 0 && scalePages > 0 {
                                    // Scales found but no fingering charts
                                    Text("Scales found, but no fingering charts")
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    if isStringInstrument {
                                        let path = getStringFingeringPath(pageNumber: 1)
                                        Text("Looking for fingerings at:\n• \(path)")
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    } else {
                                        let instrumentName = settings.selectedInstrument.replacingOccurrences(of: " ", with: "_")
                                        Text("Looking for fingerings at:\n• \(instrumentName)_1")
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                                } else {
                                    // No scales found
                                    Text("No scales found for the current configuration")
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    
                                    let basePath = getBasePath()
                                    Text("Looking for scales at path:\nnormal_\(basePath)_1")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                
                                Text("Try changing instrument, octaves, or pattern in settings")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: width, height: geo.size.height * 0.7)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedCorner(radius: 12, corners: .allCorners))
                            .overlay(RoundedCorner(radius: 12, corners: .allCorners)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, pad)
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                // 🎯 COMPREHENSIVE CLEANUP: Reset tab bar appearance when sheet dismisses
                resetTabBarAppearance()
                
                // Additional cleanup after slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    resetTabBarAppearance()
                }
            }) {
                ScaleSettingsView()
                    .environmentObject(settings)
                    .onAppear {
                        // 🎯 RESET: Clear any potential interference when sheet appears
                        resetTabBarAppearance()
                    }
                    .onDisappear {
                        // 🎯 RESET: Comprehensive cleanup when sheet disappears
                        resetTabBarAppearance()
                    }
            }
            .sheet(isPresented: $showingPianoPicker) {
                VStack(spacing: 0) {
                    Spacer()
                    Text("Choose Instrument")
                        .font(.title2).bold()
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
                        showingPianoPicker = false
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
            .onAppear {
                // Initial setup
                calculateAllPages()
                resetTabBarAppearance()
                
                // 🎯 AUTO-OPEN: Delayed auto-opening to prevent interference (only for non-Piano)
                if !hasAutoOpened && settings.selectedInstrument != "Piano" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasAutoOpened = true
                        showSettings = true
                    }
                }
            }
            .onDisappear {
                // 🎯 CLEANUP: Reset when leaving the view
                resetTabBarAppearance()
            }
            .onChange(of: showSettings) { _, isShowing in
                // 🎯 RESET: Reset appearance whenever sheet state changes
                if !isShowing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        resetTabBarAppearance()
                    }
                }
            }
            .onChange(of: settings.selectedOctaves) { _, _ in
                pageIndex = 1 // Reset to first page
                calculateAllPages()
            }
            .onChange(of: settings.selectedPattern) { _, _ in
                pageIndex = 1 // Reset to first page
                calculateAllPages()
            }
            .onChange(of: settings.includeFingerings) { _, _ in
                pageIndex = 1 // Reset to first page
                calculateAllPages()
            }
            .onChange(of: settings.selectedInstrument) { _, _ in
                pageIndex = 1 // Reset to first page
                settings.selectedOctaves = 1 // Default octave to 1
                calculateAllPages()
                
                // Reset auto-open flag when instrument changes
                hasAutoOpened = false
            }
        }
    }
}
// MARK: - Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(isLoading ? Color.accentColor.opacity(0.9) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(14)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .overlay(
                Group {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Spacer()
                        }
                    }
                }
            )
            .brightness(isLoading ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - RoundedCorner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect,
                          byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// MARK: - Previews
struct ScalesView_Previews: PreviewProvider {
    static var previews: some View {
        ScalesView()
            .environmentObject(AppSettings())
    }
}

struct ScaleSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ScaleSettingsView()
            .environmentObject(AppSettings())
    }
}
