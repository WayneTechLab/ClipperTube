import Foundation

// MARK: - Video Downloader Engine

/// Downloads YouTube videos using yt-dlp CLI tool for seamless URL-to-playback automation.
enum VideoDownloader {
    
    enum DownloadError: LocalizedError {
        case ytdlpNotInstalled
        case invalidURL
        case downloadFailed(String)
        case cancelled
        case noVideoFile
        
        var errorDescription: String? {
            switch self {
            case .ytdlpNotInstalled:
                return "yt-dlp is not installed. Install via: brew install yt-dlp"
            case .invalidURL:
                return "The provided URL is not a valid YouTube link."
            case .downloadFailed(let reason):
                return "Download failed: \(reason)"
            case .cancelled:
                return "Download was cancelled."
            case .noVideoFile:
                return "Download completed but no video file was found."
            }
        }
    }
    
    struct DownloadResult {
        var videoPath: String
        var title: String
        var duration: TimeInterval
        var videoID: String
    }
    
    struct DownloadProgress {
        var percent: Double
        var downloadedBytes: Int64
        var totalBytes: Int64
        var speed: String
        var eta: String
    }
    
    // MARK: - Public API
    
    /// Check if yt-dlp is available on the system
    static func isYtdlpInstalled() -> Bool {
        let paths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        let fm = FileManager.default
        return paths.contains { fm.fileExists(atPath: $0) }
    }
    
    /// Get the yt-dlp executable path
    static func ytdlpPath() -> String? {
        let paths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        let fm = FileManager.default
        return paths.first { fm.fileExists(atPath: $0) }
    }
    
    /// Fetch video metadata without downloading
    static func fetchMetadata(url: String) async throws -> (title: String, duration: TimeInterval, videoID: String) {
        guard let ytdlp = ytdlpPath() else {
            throw DownloadError.ytdlpNotInstalled
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlp)
        process.arguments = [
            "--print", "%(title)s|||%(duration)s|||%(id)s",
            "--no-download",
            "--no-warnings",
            url
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            throw DownloadError.invalidURL
        }
        
        let parts = output.components(separatedBy: "|||")
        let title = parts.count > 0 ? parts[0] : "Unknown"
        let duration = parts.count > 1 ? (Double(parts[1]) ?? 0) : 0
        let videoID = parts.count > 2 ? parts[2] : extractVideoID(from: url) ?? "unknown"
        
        return (title, duration, videoID)
    }
    
    /// Download video with progress tracking
    static func download(
        url: String,
        quality: VideoQuality = .best,
        outputDirectory: URL? = nil,
        onProgress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadResult {
        guard let ytdlp = ytdlpPath() else {
            throw DownloadError.ytdlpNotInstalled
        }
        
        // Prepare output directory
        let outputDir = try outputDirectory ?? prepareDownloadsDirectory()
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let outputTemplate = outputDir.appendingPathComponent("%(title).50s-\(timestamp).%(ext)s").path
        
        // First fetch metadata for the result
        let metadata = try await fetchMetadata(url: url)
        
        // Build yt-dlp arguments
        var args = [
            "-f", quality.formatString,
            "--merge-output-format", "mp4",
            "-o", outputTemplate,
            "--newline",
            "--progress",
            "--no-warnings",
            "--restrict-filenames"
        ]
        args.append(url)
        
        // Thread-safe state wrapper for readabilityHandler
        final class DownloadState: @unchecked Sendable {
            private let lock = NSLock()
            private var _path: String?
            private var _progress = DownloadProgress(percent: 0, downloadedBytes: 0, totalBytes: 0, speed: "", eta: "")
            
            var path: String? {
                get { lock.lock(); defer { lock.unlock() }; return _path }
                set { lock.lock(); defer { lock.unlock() }; _path = newValue }
            }
            var progress: DownloadProgress {
                get { lock.lock(); defer { lock.unlock() }; return _progress }
                set { lock.lock(); defer { lock.unlock() }; _progress = newValue }
            }
        }
        
        let state = DownloadState()
        
        // Run synchronously in a detached task to avoid blocking main actor
        let result: (errorMessage: String?, exitCode: Int32) = await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ytdlp)
            process.arguments = args
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            // Set up output handler to parse progress
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                
                for subline in line.components(separatedBy: .newlines) {
                    if let progress = parseProgressLine(subline) {
                        state.progress = progress
                        onProgress(progress)
                    }
                    
                    // Detect destination file
                    if subline.contains("[download] Destination:") {
                        let path = subline.replacingOccurrences(of: "[download] Destination:", with: "").trimmingCharacters(in: .whitespaces)
                        state.path = path
                    }
                    
                    // Also detect merge output
                    if subline.contains("[Merger] Merging formats into") {
                        let path = subline.replacingOccurrences(of: "[Merger] Merging formats into \"", with: "")
                            .replacingOccurrences(of: "\"", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        state.path = path
                    }
                    
                    // Detect already downloaded
                    if subline.contains("has already been downloaded") {
                        let cleaned = subline.replacingOccurrences(of: "[download]", with: "")
                            .replacingOccurrences(of: "has already been downloaded", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        if !cleaned.isEmpty {
                            state.path = cleaned
                        }
                    }
                }
            }
            
            do {
                try process.run()
            } catch {
                return (error.localizedDescription, -1)
            }
            
            process.waitUntilExit()
            
            // Clean up handler
            outputPipe.fileHandleForReading.readabilityHandler = nil
            
            let exitCode = process.terminationStatus
            var errorMessage: String?
            
            if exitCode != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                errorMessage = String(data: errorData, encoding: .utf8)
            }
            
            return (errorMessage, exitCode)
        }.value
        
        guard result.exitCode == 0 else {
            throw DownloadError.downloadFailed(result.errorMessage ?? "Unknown error")
        }
        
        // Find the downloaded file
        let finalPath: String
        if let path = state.path, FileManager.default.fileExists(atPath: path) {
            finalPath = path
        } else {
            // Search for recently created files in output directory
            if let found = findMostRecentVideo(in: outputDir) {
                finalPath = found.path
            } else {
                throw DownloadError.noVideoFile
            }
        }
        
        // Send final 100% progress
        let lastProgress = state.progress
        onProgress(DownloadProgress(percent: 100, downloadedBytes: lastProgress.totalBytes, totalBytes: lastProgress.totalBytes, speed: "Done", eta: "0s"))
        
        return DownloadResult(
            videoPath: finalPath,
            title: metadata.title,
            duration: metadata.duration,
            videoID: metadata.videoID
        )
    }
    
    /// Quick download without progress (simpler API)
    static func downloadSimple(url: String, quality: VideoQuality = .best) async throws -> DownloadResult {
        try await download(url: url, quality: quality) { _ in }
    }
    
    // MARK: - Helpers
    
    private static func prepareDownloadsDirectory() throws -> URL {
        let fm = FileManager.default
        let directory = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent("CliperTubeDownloads", isDirectory: true)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    
    private static func parseProgressLine(_ line: String) -> DownloadProgress? {
        // Example: [download]  45.2% of  125.50MiB at    5.23MiB/s ETA 00:15
        guard line.contains("[download]") && line.contains("%") else { return nil }
        
        var percent: Double = 0
        var speed = ""
        var eta = ""
        var downloaded: Int64 = 0
        var total: Int64 = 0
        
        // Extract percentage
        if let percentRange = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
            let percentStr = line[percentRange].dropLast()
            percent = Double(percentStr) ?? 0
        }
        
        // Extract total size
        if let sizeRange = line.range(of: #"of\s+(\d+\.?\d*)(Ki|Mi|Gi)?B"#, options: .regularExpression) {
            let sizeStr = String(line[sizeRange]).replacingOccurrences(of: "of", with: "").trimmingCharacters(in: .whitespaces)
            total = parseSize(sizeStr)
            downloaded = Int64(Double(total) * (percent / 100))
        }
        
        // Extract speed
        if let speedRange = line.range(of: #"at\s+[\d.]+\s*(Ki|Mi|Gi)?B/s"#, options: .regularExpression) {
            speed = String(line[speedRange]).replacingOccurrences(of: "at", with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // Extract ETA
        if let etaRange = line.range(of: #"ETA\s+\d+:\d+"#, options: .regularExpression) {
            eta = String(line[etaRange]).replacingOccurrences(of: "ETA", with: "").trimmingCharacters(in: .whitespaces)
        }
        
        return DownloadProgress(
            percent: percent,
            downloadedBytes: downloaded,
            totalBytes: total,
            speed: speed,
            eta: eta
        )
    }
    
    private static func parseSize(_ sizeStr: String) -> Int64 {
        let cleaned = sizeStr.trimmingCharacters(in: .whitespaces)
        var multiplier: Int64 = 1
        var numStr = cleaned
        
        if cleaned.contains("GiB") {
            multiplier = 1024 * 1024 * 1024
            numStr = cleaned.replacingOccurrences(of: "GiB", with: "")
        } else if cleaned.contains("MiB") {
            multiplier = 1024 * 1024
            numStr = cleaned.replacingOccurrences(of: "MiB", with: "")
        } else if cleaned.contains("KiB") {
            multiplier = 1024
            numStr = cleaned.replacingOccurrences(of: "KiB", with: "")
        } else if cleaned.contains("B") {
            numStr = cleaned.replacingOccurrences(of: "B", with: "")
        }
        
        if let value = Double(numStr.trimmingCharacters(in: .whitespaces)) {
            return Int64(value * Double(multiplier))
        }
        return 0
    }
    
    private static func findMostRecentVideo(in directory: URL) -> URL? {
        let fm = FileManager.default
        let videoExtensions = ["mp4", "mov", "webm", "mkv", "m4v"]
        
        guard let contents = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey]) else {
            return nil
        }
        
        let videos = contents.filter { videoExtensions.contains($0.pathExtension.lowercased()) }
        
        let recent = videos
            .compactMap { url -> (URL, Date)? in
                guard let attrs = try? fm.attributesOfItem(atPath: url.path),
                      let created = attrs[.creationDate] as? Date else { return nil }
                return (url, created)
            }
            .sorted { $0.1 > $1.1 }
            .first
        
        // Only return if created within last 5 minutes
        if let found = recent, Date().timeIntervalSince(found.1) < 300 {
            return found.0
        }
        
        return nil
    }
    
    private static func extractVideoID(from url: String) -> String? {
        let patterns = [
            "(?:v=)([A-Za-z0-9_-]{11})",
            "(?:youtu\\.be/)([A-Za-z0-9_-]{11})",
            "(?:shorts/)([A-Za-z0-9_-]{11})",
            "(?:embed/)([A-Za-z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(url.startIndex..<url.endIndex, in: url)
            if let match = regex.firstMatch(in: url, range: range),
               match.numberOfRanges > 1,
               let idRange = Range(match.range(at: 1), in: url) {
                return String(url[idRange])
            }
        }
        
        return nil
    }
}

// MARK: - Video Quality Options

enum VideoQuality: String, CaseIterable, Identifiable {
    case best = "Best Quality"
    case high = "1080p"
    case medium = "720p"
    case low = "480p"
    case audio = "Audio Only"
    
    var id: String { rawValue }
    
    var formatString: String {
        switch self {
        case .best:
            return "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        case .high:
            return "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best"
        case .medium:
            return "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best"
        case .low:
            return "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480][ext=mp4]/best"
        case .audio:
            return "bestaudio[ext=m4a]/bestaudio"
        }
    }
}
