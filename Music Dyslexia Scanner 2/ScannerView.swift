import SwiftUI
import PhotosUI
import UIKit
import Photos
import PDFKit
import UniformTypeIdentifiers
import AVFoundation

// MARK: - Permission Status Enums
enum CameraPermissionStatus {
    case undetermined
    case denied
    case granted
}

enum PhotosPermissionStatus {
    case undetermined
    case denied
    case limited
    case granted
}

// MARK: - Error Handling
enum SheetMusicError: Error, LocalizedError {
    case apiError(String)
    case networkError(String)
    case configurationError(String)
    case imageProcessingError(String)
    case noInternetConnection
    case fastFailError(String)
    case insufficientTextError(String)
    case unprocessableContent(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message): return "API Error: \(message)"
        case .networkError(let message): return "Network Error: \(message)"
        case .configurationError(let message): return "Configuration Error: \(message)"
        case .imageProcessingError(let message): return "Image Processing Error: \(message)"
        case .noInternetConnection: return "Process failed. Please connect to internet"
        case .fastFailError(let message): return message
        case .insufficientTextError(let message): return message
        case .unprocessableContent(let message): return message
        }
    }
}

// MARK: - Image Processing Extension
extension UIImage {
    func toGrayscale() -> UIImage? {
        guard let currentCGImage = cgImage else { return nil }
        let currentCIImage = CIImage(cgImage: currentCGImage)
        
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(currentCIImage, forKey: "inputImage")
        filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")
        filter?.setValue(1.0, forKey: "inputIntensity")
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    func compressedForStorage(maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 1.0
        let maxBytes = maxSizeKB * 1024
        
        guard var imageData = self.jpegData(compressionQuality: compression) else { return nil }
        
        while imageData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            guard let compressedData = self.jpegData(compressionQuality: compression) else { break }
            imageData = compressedData
        }
        
        return imageData
    }
    
    func optimizedForAPI(maxSize: CGSize = CGSize(width: 1024, height: 1024), quality: CGFloat = 0.85) -> Data? {
        var targetImage = self
        
        if size.width > maxSize.width || size.height > maxSize.height {
            let aspectRatio = size.width / size.height
            var newSize: CGSize
            
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            draw(in: CGRect(origin: .zero, size: newSize))
            targetImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
            UIGraphicsEndImageContext()
            
            print("📸 Original size: \(size), resized to: \(newSize)")
        }
        
        return targetImage.jpegData(compressionQuality: quality)
    }
}

// MARK: - Data Models
struct PieceIdentification: Codable {
    let title: String
    let composer: String
    let sceneMovement: String
    let confidence: String
    let reasoning: String
    
    enum CodingKeys: String, CodingKey {
        case title, composer, confidence, reasoning
        case sceneMovement = "scene_movement"
    }
    
    var conciseTitle: String {
        return title
    }
    
    var displayTitle: String {
        return "\(title) by \(composer)"
    }
}

struct VideoResult: Identifiable, Codable {
    let id: UUID
    let videoId: String
    let title: String
    let channel: String
    let videoUrl: String
    let views: Int
    let likes: Int
    let duration: String
    let durationSeconds: Int
    let searchStrategy: String
    let titleMatchScore: Double?
    let composerMatchScore: Double?
    let sceneMatchScore: Double?
    let durationMatchScore: Double?
    let overallAccuracyScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case videoId = "id"
        case title, channel, views, likes, duration
        case videoUrl = "url"
        case durationSeconds = "duration_seconds"
        case searchStrategy = "search_strategy"
        case titleMatchScore = "title_match_score"
        case composerMatchScore = "composer_match_score"
        case sceneMatchScore = "scene_match_score"
        case durationMatchScore = "duration_match_score"
        case overallAccuracyScore = "overall_accuracy_score"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID()
        self.videoId = try container.decode(String.self, forKey: .videoId)
        self.title = try container.decode(String.self, forKey: .title)
        self.channel = try container.decode(String.self, forKey: .channel)
        self.videoUrl = try container.decode(String.self, forKey: .videoUrl)
        self.views = try container.decode(Int.self, forKey: .views)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        self.searchStrategy = try container.decode(String.self, forKey: .searchStrategy)
        self.titleMatchScore = try container.decodeIfPresent(Double.self, forKey: .titleMatchScore)
        self.composerMatchScore = try container.decodeIfPresent(Double.self, forKey: .composerMatchScore)
        self.sceneMatchScore = try container.decodeIfPresent(Double.self, forKey: .sceneMatchScore)
        self.durationMatchScore = try container.decodeIfPresent(Double.self, forKey: .durationMatchScore)
        self.overallAccuracyScore = try container.decodeIfPresent(Double.self, forKey: .overallAccuracyScore)
    }
}

struct EnhancedAPIResponse: Codable {
    let pieceIdentification: PieceIdentification
    let videos: [VideoResult]
    
    enum CodingKeys: String, CodingKey {
        case pieceIdentification = "piece_identification"
        case videos
    }
}

struct ScanHistory: Identifiable, Codable {
    let id: UUID
    let pieceIdentification: PieceIdentification
    let videos: [VideoResult]
    let processedImage: Data?
    let timestamp: Date
    
    var displayTitle: String {
        return pieceIdentification.displayTitle
    }
    
    var processedUIImage: UIImage? {
        guard let imageData = processedImage else { return nil }
        return UIImage(data: imageData)
    }
    
    init(pieceIdentification: PieceIdentification, videos: [VideoResult], processedImage: Data?, timestamp: Date) {
        self.id = UUID()
        self.pieceIdentification = pieceIdentification
        self.videos = videos
        self.processedImage = processedImage
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID()
        self.pieceIdentification = try container.decode(PieceIdentification.self, forKey: .pieceIdentification)
        self.videos = try container.decode([VideoResult].self, forKey: .videos)
        self.processedImage = try container.decodeIfPresent(Data.self, forKey: .processedImage)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    enum CodingKeys: String, CodingKey {
        case pieceIdentification, videos, processedImage, timestamp
    }
}

enum NavigationState {
    case home
    case scanResult(ScanHistory)
}

class HomeViewReference: ObservableObject {
    var resumeSlideshow: (() -> Void)?
}

enum ImageProcessingState: Equatable {
    case idle
    case loading(String, isSlowInternet: Bool = false)
    case completed(UIImage, [VideoResult])
    case failed(String)
    case networkErrorOccurred
    case noInternetConnection
    case fastFailError(String)
    case unprocessableContent(String)
    
    var message: String {
        switch self {
        case .loading(let msg, _): return msg
        case .completed(_, _): return "✅ Finished!"
        case .failed(let error): return "❌ \(error)"
        case .networkErrorOccurred: return ""
        case .noInternetConnection: return "Process failed. Please connect to internet"
        case .fastFailError(let message): return message
        case .unprocessableContent(let message): return message
        case .idle: return ""
        }
    }
    
    var isSlowInternet: Bool {
        switch self {
        case .loading(_, let slow): return slow
        default: return false
        }
    }
    
    static func == (lhs: ImageProcessingState, rhs: ImageProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let lhsMsg, let lhsSlow), .loading(let rhsMsg, let rhsSlow)):
            return lhsMsg == rhsMsg && lhsSlow == rhsSlow
        case (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        case (.networkErrorOccurred, .networkErrorOccurred):
            return true
        case (.noInternetConnection, .noInternetConnection):
            return true
        case (.fastFailError(let lhsError), .fastFailError(let rhsError)):
            return lhsError == rhsError
        case (.unprocessableContent(let lhsError), .unprocessableContent(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Enhanced Image Processor
class ImageProcessor: ObservableObject {
    @Published var processingState: ImageProcessingState = .idle
    
    private var currentTask: URLSessionDataTask?
    private let railwayAPIURL = "https://runpodfolder-production.up.railway.app/scan"
    private let healthAPIURL = "https://runpodfolder-production.up.railway.app/health"
    private var isCancelled = false
    
    var selectedInstrument: String = "Alto Saxophone"
    
    init() {}
    
    func cancelProcessing() {
        print("🛑 Cancelling current processing task")
        isCancelled = true
        currentTask?.cancel()
        
        DispatchQueue.main.async {
            self.processingState = .idle
        }
    }
    
    func setInstrument(_ instrument: String) {
        selectedInstrument = instrument.lowercased()
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .dataNotAllowed:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    func checkAPIHealth() {
        guard let url = URL(string: healthAPIURL) else { return }
        
        var request = URLRequest(url: url)
        request.allowsCellularAccess = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Health check failed: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("🏥 API Health Status: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    private func checkInternetConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://www.google.com") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.allowsCellularAccess = true
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🌐 No internet connection: \(error)")
                    completion(false)
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Internet connection: HTTP \(httpResponse.statusCode)")
                    completion(httpResponse.statusCode == 200)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    private func checkNetworkSpeed(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: healthAPIURL) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.allowsCellularAccess = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            let isSlowInternet = timeElapsed > 2.0 || error != nil
            
            print("🌐 Network ping time: \(String(format: "%.2f", timeElapsed))s - \(isSlowInternet ? "SLOW" : "FAST")")
            
            DispatchQueue.main.async {
                completion(isSlowInternet)
            }
        }.resume()
    }
    
    func processImage(_ image: UIImage, completion: @escaping (PieceIdentification?, UIImage?, [VideoResult]?) -> Void) {
        print("🚀 Starting Enhanced Railway API processing with fast-fail")
        print("📏 Original image size: \(image.size)")
        
        isCancelled = false
        
        DispatchQueue.main.async {
            self.processingState = .loading("🔍 Checking connection...", isSlowInternet: false)
        }
        
        checkInternetConnection { hasInternet in
            guard !self.isCancelled else {
                print("🛑 Processing cancelled during internet check")
                return
            }
            
            if !hasInternet {
                DispatchQueue.main.async {
                    guard !self.isCancelled else { return }
                    self.processingState = .noInternetConnection
                    completion(nil, nil, nil)
                }
                return
            }
            
            self.checkNetworkSpeed { isSlowInternet in
                guard !self.isCancelled else {
                    print("🛑 Processing cancelled during network speed check")
                    return
                }
                
                DispatchQueue.main.async {
                    guard !self.isCancelled else { return }
                    self.processingState = .loading("🔍 Analyzing sheet music...", isSlowInternet: isSlowInternet)
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    guard !self.isCancelled else {
                        print("🛑 Processing cancelled during image processing")
                        return
                    }
                    
                    let processedImage = image.toGrayscale() ?? image
                    
                    guard let imageData = processedImage.optimizedForAPI() else {
                        DispatchQueue.main.async {
                            guard !self.isCancelled else { return }
                            self.processingState = .failed("❌ Failed to process image")
                            completion(nil, processedImage, nil)
                        }
                        return
                    }
                    
                    let base64String = imageData.base64EncodedString()
                    
                    self.sendToEnhancedRailwayAPI(imageBase64: base64String, instrument: self.selectedInstrument) { result in
                        guard !self.isCancelled else {
                            print("🛑 Processing cancelled - ignoring API response")
                            return
                        }
                        
                        switch result {
                        case .success(let apiResponse):
                            if !apiResponse.videos.isEmpty {
                                DispatchQueue.main.async {
                                    guard !self.isCancelled else { return }
                                    self.processingState = .completed(processedImage, apiResponse.videos)
                                    completion(apiResponse.pieceIdentification, processedImage, apiResponse.videos)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        guard !self.isCancelled else { return }
                                        self.processingState = .idle
                                    }
                                }
                            } else {
                                let errorMessage = "No recordings found for this piece"
                                DispatchQueue.main.async {
                                    guard !self.isCancelled else { return }
                                    self.processingState = .failed("❌ \(errorMessage)")
                                    completion(nil, processedImage, nil)
                                }
                            }
                            
                        case .failure(let error):
                            if self.isNetworkError(error) {
                                print("🌐 Network error detected - letting iOS handle it")
                                DispatchQueue.main.async {
                                    guard !self.isCancelled else { return }
                                    self.processingState = .networkErrorOccurred
                                }
                            } else {
                                DispatchQueue.main.async {
                                    guard !self.isCancelled else { return }
                                    
                                    if let fastFailError = error as? SheetMusicError {
                                        switch fastFailError {
                                        case .fastFailError(let message):
                                            self.processingState = .fastFailError(message)
                                        case .unprocessableContent(let message):
                                            self.processingState = .unprocessableContent(message)
                                        case .insufficientTextError(let message):
                                            self.processingState = .unprocessableContent(message)
                                        default:
                                            self.processingState = .failed("❌ Processing failed: \(error.localizedDescription)")
                                        }
                                    } else {
                                        self.processingState = .failed("❌ Processing failed: \(error.localizedDescription)")
                                    }
                                    completion(nil, processedImage, nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendToEnhancedRailwayAPI(imageBase64: String, instrument: String, completion: @escaping (Result<EnhancedAPIResponse, Error>) -> Void) {
        print("🌐 Sending request to Enhanced Railway API with fast-fail...")
        print("   Instrument: \(instrument)")
        print("   API URL: \(railwayAPIURL)")
        print("   Image size: \(imageBase64.count) characters")
        
        guard let url = URL(string: railwayAPIURL) else {
            completion(.failure(SheetMusicError.configurationError("Invalid API URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.allowsCellularAccess = true
        
        let payload: [String: Any] = [
            "image": imageBase64,
            "instrument": instrument
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(SheetMusicError.apiError("Failed to serialize request: \(error)")))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("🛑 Network request was cancelled")
                return
            }
            
            if self.isCancelled {
                print("🛑 Ignoring response from cancelled request")
                return
            }
            
            if let error = error {
                if self.isNetworkError(error) {
                    print("🌐 Enhanced Railway API network error detected - letting iOS handle it")
                    DispatchQueue.main.async {
                        guard !self.isCancelled else { return }
                        self.processingState = .networkErrorOccurred
                    }
                    return
                }
                completion(.failure(SheetMusicError.networkError("API request failed: \(error)")))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(SheetMusicError.apiError("Invalid response")))
                return
            }
            
            print("📡 Enhanced Railway API Response Status: \(httpResponse.statusCode)")
            
            guard let data = data else {
                completion(.failure(SheetMusicError.apiError("No data received from API")))
                return
            }
            
            print("📥 Data received: \(data.count) bytes")
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let apiResponse = try JSONDecoder().decode(EnhancedAPIResponse.self, from: data)
                    print("✅ Successfully parsed enhanced API response")
                    print("📺 Found \(apiResponse.videos.count) videos")
                    print("🎼 Title: \(apiResponse.pieceIdentification.title)")
                    print("🎭 Composer: \(apiResponse.pieceIdentification.composer)")
                    completion(.success(apiResponse))
                } catch {
                    print("❌ JSON parsing failed: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("📄 Raw response: \(dataString)")
                    }
                    completion(.failure(SheetMusicError.apiError("Failed to parse API response: \(error)")))
                }
                
            case 422:
                do {
                    let apiResponse = try JSONDecoder().decode(EnhancedAPIResponse.self, from: data)
                    let reason = apiResponse.pieceIdentification.reasoning
                    print("⚠️ Fast-fail response: \(reason)")
                    
                    let userFriendlyMessage: String
                    if reason.lowercased().contains("no readable text") || reason.lowercased().contains("not enough readable text") {
                        userFriendlyMessage = "Image text not clear enough. Try uploading a sharper image of sheet music."
                    } else if reason.lowercased().contains("does not appear to contain sheet music") {
                        userFriendlyMessage = "Image doesn't appear to contain sheet music. Please upload an image of sheet music."
                    } else if reason.lowercased().contains("could not identify piece title and composer") {
                        userFriendlyMessage = "Could not identify the piece title and composer. Try uploading an image showing the title and composer clearly."
                    } else {
                        userFriendlyMessage = reason
                    }
                    
                    completion(.failure(SheetMusicError.unprocessableContent(userFriendlyMessage)))
                } catch {
                    print("❌ Failed to parse fast-fail response: \(error)")
                    completion(.failure(SheetMusicError.unprocessableContent("Image doesn't contain readable sheet music information.")))
                }
                
            case 400:
                if let dataString = String(data: data, encoding: .utf8) {
                    print("❌ Bad Request: \(dataString)")
                    completion(.failure(SheetMusicError.apiError("Bad request: \(dataString)")))
                } else {
                    completion(.failure(SheetMusicError.apiError("Bad request (status 400)")))
                }
                
            case 500:
                if let dataString = String(data: data, encoding: .utf8) {
                    print("❌ Server Error: \(dataString)")
                    completion(.failure(SheetMusicError.apiError("Server error: \(dataString)")))
                } else {
                    completion(.failure(SheetMusicError.apiError("Server error (status 500)")))
                }
                
            default:
                if let dataString = String(data: data, encoding: .utf8) {
                    print("❌ API Error Response: \(dataString)")
                    completion(.failure(SheetMusicError.apiError("API error (status \(httpResponse.statusCode)): \(dataString)")))
                } else {
                    completion(.failure(SheetMusicError.apiError("API request failed with status \(httpResponse.statusCode)")))
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
}

// MARK: - History Manager
class HistoryManager: ObservableObject {
    @Published var scanHistory: [ScanHistory] = []
    
    private let historyFileName = "scanHistory.json"
    private var historyFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(historyFileName)
    }
    
    init() {
        migrateFromUserDefaults()
        loadHistory()
    }
    
    private func migrateFromUserDefaults() {
        let oldKey = "ScanHistory"
        
        if UserDefaults.standard.data(forKey: oldKey) != nil && !FileManager.default.fileExists(atPath: historyFileURL.path) {
            print("🔄 Migrating scan history from UserDefaults to file storage...")
            
            if let data = UserDefaults.standard.data(forKey: oldKey),
               let decoded = try? JSONDecoder().decode([ScanHistory].self, from: data) {
                
                do {
                    let encoded = try JSONEncoder().encode(decoded)
                    try encoded.write(to: historyFileURL)
                    print("✅ Successfully migrated \(decoded.count) scans to file storage")
                    
                    UserDefaults.standard.removeObject(forKey: oldKey)
                    print("🗑️ Cleaned up old UserDefaults data")
                } catch {
                    print("❌ Failed to migrate data: \(error)")
                }
            }
        }
    }
    
    func addScan(pieceIdentification: PieceIdentification, videos: [VideoResult], processedImage: UIImage?) {
        let imageData = processedImage?.compressedForStorage(maxSizeKB: 300)
        
        let newScan = ScanHistory(
            pieceIdentification: pieceIdentification,
            videos: videos,
            processedImage: imageData,
            timestamp: Date()
        )
        
        scanHistory.insert(newScan, at: 0)
        
        if scanHistory.count > 50 {
            scanHistory = Array(scanHistory.prefix(50))
            print("📝 Trimmed history to 50 most recent scans")
        }
        
        saveHistory()
    }
    
    private func saveHistory() {
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoded = try JSONEncoder().encode(self.scanHistory)
                try encoded.write(to: self.historyFileURL)
                print("💾 Saved \(self.scanHistory.count) scans to file (\(encoded.count) bytes)")
            } catch {
                print("❌ Failed to save history: \(error)")
            }
        }
    }
    
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoded = try JSONDecoder().decode([ScanHistory].self, from: data)
            scanHistory = decoded
            print("📂 Loaded \(decoded.count) scans from file")
        } catch {
            if FileManager.default.fileExists(atPath: historyFileURL.path) {
                print("❌ Failed to load history: \(error)")
            } else {
                print("📝 No existing history file found - starting fresh")
            }
            scanHistory = []
        }
    }
    
    func deleteScan(_ scan: ScanHistory) {
        if let index = scanHistory.firstIndex(where: { $0.id == scan.id }) {
            scanHistory.remove(at: index)
            print("⚡ Fast delete: Removed scan at index \(index)")
            saveHistory()
        }
    }
    
    func deleteScans(_ scansToDelete: [ScanHistory]) {
        let idsToDelete = Set(scansToDelete.map { $0.id })
        let originalCount = scanHistory.count
        
        scanHistory.removeAll { idsToDelete.contains($0.id) }
        
        if scanHistory.count != originalCount {
            print("🚀 Batch delete: Removed \(originalCount - scanHistory.count) scans")
            saveHistory()
        }
    }
    
    func clearAllScans() {
        scanHistory.removeAll()
        print("💨 Clear all: Removed all scan history")
        saveHistory()
    }
    
    func getHistoryFileSize() -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: historyFileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            return "Unknown"
        }
        return "No file"
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let state: ImageProcessingState
    let onCancel: () -> Void
    @ObservedObject var processor: ImageProcessor
    @State private var rotation: Double = 0
    @State private var secondsElapsed: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        if case .networkErrorOccurred = state {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(spacing: 0) {
                HStack {
                    Text("Scanner")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(Angle(degrees: rotation))
                                .onAppear {
                                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                        rotation = 360
                                    }
                                }
                            
                            Text("\(secondsElapsed)")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 16) {
                            Text("Average 10-30 seconds.\nIf taking longer, try reloading!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            if state.isSlowInternet {
                                HStack(spacing: 6) {
                                    Text("*")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .fontWeight(.bold)
                                    
                                    Text("Internet slow, please wait")
                                        .font(.callout)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                }
                                .transition(.opacity.combined(with: .scale))
                                .animation(.easeInOut(duration: 0.5), value: state.isSlowInternet)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        )
    }
    
    private func startTimer() {
        secondsElapsed = 1
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            secondsElapsed += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        secondsElapsed = 0
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var historyManager: HistoryManager
    @StateObject private var processor = ImageProcessor()
    @EnvironmentObject var settings: AppSettings
    let homeViewRef: HomeViewReference
    let hasShownInstrumentPickerBefore: Bool
    let onSelectScan: (ScanHistory) -> Void
    let onAddScan: () -> Void
    
    @State private var showingInstrumentPicker = false
    @State private var currentImageSet = 0
    @State private var imageOpacity: Double = 1.0
    @State private var slideshowTimer: Timer?
    @State private var slideshowPaused = false
    
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if historyManager.scanHistory.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: { showingInstrumentPicker = true }) {
                                HStack(spacing: 4) {
                                    Text(settings.selectedInstrument)
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                        
                        Divider()
                        
                        VStack(spacing: 20) {
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Instructions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("1.")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                        Text("Scan your music showing the title and composer")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("2.")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                        Text("Sheet Scan retrieves professional recordings of your piece")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Tips for a good scan")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("•")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                            .fontWeight(.bold)
                                        Text("Include title and composer clearly")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("•")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                            .fontWeight(.bold)
                                        Text("Keep camera steady for sharp text")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            
                            Text("Examples")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 30)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Image(getGoodImageName())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green, lineWidth: 2)
                                        )
                                        .opacity(imageOpacity)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack {
                                    Image(getBadImageName())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.red, lineWidth: 2)
                                        )
                                        .opacity(imageOpacity)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 30)
                            
                            Button(action: {
                                slideshowPaused = true
                                slideshowTimer?.invalidate()
                                onAddScan()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Scan Music")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: { showingInstrumentPicker = true }) {
                                HStack(spacing: 4) {
                                    Text(settings.selectedInstrument)
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Spacer()
                            
                            Button(action: onAddScan) {
                                Image(systemName: "plus")
                                    .font(.system(size: 25, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    ScrollViewReader { proxy in
                        List {
                            ForEach(historyManager.scanHistory) { scan in
                                ScanRowButton(scan: scan) {
                                    onSelectScan(scan)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color(.systemBackground))
                                .id(scan.id)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            historyManager.deleteScan(scan)
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollIndicators(.hidden)
                        .background(Color(.systemBackground))
                        .onAppear {
                            if let firstScan = historyManager.scanHistory.first {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(firstScan.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingInstrumentPicker) {
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
                    showingInstrumentPicker = false
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
        .onChange(of: settings.selectedInstrument) { _, newInstrument in
            processor.setInstrument(newInstrument)
        }
        .onAppear {
            processor.setInstrument(settings.selectedInstrument)
            
            homeViewRef.resumeSlideshow = resumeSlideshow
            
            startSlideshow()
            slideshowPaused = false
            
            // Only show instrument picker on very first app launch
            if !hasShownInstrumentPickerBefore {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Mark that we've shown the picker
                    UserDefaults.standard.set(true, forKey: "HasShownInstrumentPicker")
                    showingInstrumentPicker = true
                }
            }
        }
        .onDisappear {
            slideshowTimer?.invalidate()
        }
    }
    
    private func startSlideshow() {
        slideshowTimer?.invalidate()
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard !slideshowPaused else { return }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                imageOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                currentImageSet = (currentImageSet + 1) % 4
                withAnimation(.easeInOut(duration: 1.0)) {
                    imageOpacity = 1.0
                }
            }
        }
    }
    
    private func resumeSlideshow() {
        slideshowPaused = false
        startSlideshow()
    }
    
    private func getGoodImageName() -> String {
        switch currentImageSet {
        case 0: return "Good"
        case 1: return "Good2"
        case 2: return "Good3"
        case 3: return "Good4"
        default: return "Good"
        }
    }
    
    private func getBadImageName() -> String {
        switch currentImageSet {
        case 0: return "Bad"
        case 1: return "Bad2"
        case 2: return "Bad3"
        case 3: return "Bad4"
        default: return "Bad"
        }
    }
}

struct ScanRowButton: View {
    let scan: ScanHistory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(scan.displayTitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(scan.timestamp, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScannerView: View {
    @StateObject private var processor = ImageProcessor()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var settings = AppSettings()
    @State private var navigationState: NavigationState = .home
    @State private var showOptions = false
    @State private var showCamera = false
    @State private var showImagePicker = false
    @StateObject private var homeViewRef = HomeViewReference()
    
    // Check if instrument picker has been shown before (persisted across app launches)
    private var hasShownInstrumentPickerBefore: Bool {
        UserDefaults.standard.bool(forKey: "HasShownInstrumentPicker")
    }
    
    // Permission states
    @State private var cameraPermission: CameraPermissionStatus = .undetermined
    @State private var photosPermission: PhotosPermissionStatus = .undetermined
    
    // Permission overlay states
    @State private var showCameraPermissionOverlay = false
    @State private var showPhotosPermissionOverlay = false
    
    var body: some View {
        ZStack {
            Group {
                switch navigationState {
                case .home:
                    HomeView(
                        historyManager: historyManager,
                        homeViewRef: homeViewRef,
                        hasShownInstrumentPickerBefore: hasShownInstrumentPickerBefore,
                        onSelectScan: { scan in
                            navigationState = .scanResult(scan)
                        },
                        onAddScan: {
                            showOptions = true
                        }
                    )
                    .environmentObject(settings)
                    
                case .scanResult(let scan):
                    EnhancedScanResultView(
                        scan: scan,
                        onBack: {
                            navigationState = .home
                        },
                        onDelete: {
                            navigationState = .home
                            historyManager.deleteScan(scan)
                        }
                    )
                }
            }
            
            if isProcessing {
                ProcessingOverlay(
                    state: processor.processingState,
                    onCancel: {
                        processor.cancelProcessing()
                    },
                    processor: processor
                )
            }
        }
        // Permission Overlays
        .overlay(
            Group {
                // Camera Permission Overlay
                if showCameraPermissionOverlay {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(120)
                    
                    VStack(spacing: 16) {
                        Text("📸 Camera Access Required")
                            .font(.headline)
                            .padding(.top, 20)
                        Text("Please enable camera access in Settings to take photos of your sheet music.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Open Settings") {
                            openSettings()
                            showCameraPermissionOverlay = false
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
                
                // Photos Permission Overlay
                if showPhotosPermissionOverlay {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(120)
                    
                    VStack(spacing: 16) {
                        Text("📱 Photos Access Required")
                            .font(.headline)
                            .padding(.top, 20)
                        Text("Please enable photo library access in Settings to choose photos of your sheet music.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Open Settings") {
                            openSettings()
                            showPhotosPermissionOverlay = false
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
        .confirmationDialog("", isPresented: $showOptions, titleVisibility: .hidden) {
            Button("Take Photo") {
                handleTakePhotoTap()
            }
            Button("Choose Photo") {
                handleChoosePhotoTap()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera, onDismiss: {
            homeViewRef.resumeSlideshow?()
        }) {
            CameraCaptureView { image in processImage(image) }
                .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            homeViewRef.resumeSlideshow?()
        }) {
            ImagePicker { image in processImage(image) }
        }
        .alert("Error", isPresented: .constant(isError), actions: {
            Button("OK") { processor.processingState = .idle }
        }, message: {
            switch processor.processingState {
            case .failed(let error):
                Text(error)
            case .noInternetConnection:
                Text("Process failed. Please connect to internet")
            case .fastFailError(let message):
                Text(message)
            case .unprocessableContent(let message):
                Text(message)
            default:
                Text("An error occurred")
            }
        })
        .onAppear {
            processor.setInstrument(settings.selectedInstrument)
            processor.checkAPIHealth()
            checkInitialPermissions()
        }
        .onChange(of: settings.selectedInstrument) { _, newInstrument in
            processor.setInstrument(newInstrument)
        }
        .onChange(of: showOptions) { _, isShowing in
            if !isShowing {
                homeViewRef.resumeSlideshow?()
            }
        }
    }
    
    // MARK: - Permission Checking Functions
    
    private func checkInitialPermissions() {
        cameraPermission = getCurrentCameraPermission()
        photosPermission = getCurrentPhotosPermission()
    }
    
    private func getCurrentCameraPermission() -> CameraPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .undetermined
        case .denied, .restricted:
            return .denied
        case .authorized:
            return .granted
        @unknown default:
            return .undetermined
        }
    }
    
    private func getCurrentPhotosPermission() -> PhotosPermissionStatus {
        if #available(iOS 14, *) {
            switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            case .notDetermined:
                return .undetermined
            case .denied, .restricted:
                return .denied
            case .limited:
                return .limited
            case .authorized:
                return .granted
            @unknown default:
                return .undetermined
            }
        } else {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                return .undetermined
            case .denied, .restricted:
                return .denied
            case .authorized:
                return .granted
            @unknown default:
                return .undetermined
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraPermission = self.getCurrentCameraPermission()
                if granted {
                    self.showCamera = true
                } else {
                    self.showCameraPermissionOverlay = true
                }
            }
        }
    }
    
    private func requestPhotosPermission() {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.photosPermission = self.getCurrentPhotosPermission()
                    if status == .authorized || status == .limited {
                        self.showImagePicker = true
                    } else {
                        self.showPhotosPermissionOverlay = true
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.photosPermission = self.getCurrentPhotosPermission()
                    if status == .authorized {
                        self.showImagePicker = true
                    } else {
                        self.showPhotosPermissionOverlay = true
                    }
                }
            }
        }
    }
    
    // MARK: - Button Handlers
    
    private func handleTakePhotoTap() {
        cameraPermission = getCurrentCameraPermission()
        
        switch cameraPermission {
        case .granted:
            showCamera = true
        case .denied:
            showCameraPermissionOverlay = true
        case .undetermined:
            requestCameraPermission()
        }
    }
    
    private func handleChoosePhotoTap() {
        photosPermission = getCurrentPhotosPermission()
        
        switch photosPermission {
        case .granted, .limited:
            showImagePicker = true
        case .denied:
            showPhotosPermissionOverlay = true
        case .undetermined:
            requestPhotosPermission()
        }
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Processing States
    
    private var isProcessing: Bool {
        switch processor.processingState {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    private var isError: Bool {
        switch processor.processingState {
        case .failed(_), .noInternetConnection, .fastFailError(_), .unprocessableContent(_):
            return true
        default:
            return false
        }
    }
    
    private func processImage(_ image: UIImage) {
        // Proceed with processing directly
        processor.processImage(image) { pieceIdentification, processedImg, videos in
            if let pieceIdentification = pieceIdentification, let videos = videos, !videos.isEmpty {
                historyManager.addScan(pieceIdentification: pieceIdentification, videos: videos, processedImage: processedImg)
                
                let imageData = processedImg?.jpegData(compressionQuality: 0.8)
                let newScan = ScanHistory(
                    pieceIdentification: pieceIdentification,
                    videos: videos,
                    processedImage: imageData,
                    timestamp: Date()
                )
                
                navigationState = .scanResult(newScan)
            }
        }
    }
}

// MARK: - Scan Result View
struct EnhancedScanResultView: View {
    let scan: ScanHistory
    let onBack: () -> Void
    let onDelete: () -> Void
    
    private func formatTitle(_ title: String) -> String {
        let maxCharsPerLine = 20
        let words = title.split(separator: " ").map(String.init)
        var lines: [String] = []
        var currentLine = ""
        
        for word in words {
            let testLine = currentLine.isEmpty ? word : "\(currentLine) \(word)"
            
            if testLine.count <= maxCharsPerLine {
                currentLine = testLine
            } else {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = word
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.joined(separator: "\n")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Home")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
                Text(formatTitle(scan.pieceIdentification.conciseTitle))
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(scan.videos.enumerated()), id: \.element.id) { index, video in
                        EnhancedVideoRowView(video: video, rank: index + 1)
                    }
                }
                .padding(.top, 10)
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Video Row View
struct EnhancedVideoRowView: View {
    let video: VideoResult
    let rank: Int
    
    var body: some View {
        Button(action: {
            openYouTubeVideo(video.videoUrl)
        }) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 35, height: 35)
                    
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    Text("📺 \(video.channel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Text("⏱️ \(video.duration)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("👀 \(formatNumber(video.views))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("Open")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private func openYouTubeVideo(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Camera and Image Pickers
struct CameraCaptureView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.onImageSelected(uiImage)
                    }
                }
            }
        }
    }
}
