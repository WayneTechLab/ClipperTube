import Foundation

/// Checks for app updates via GitHub Releases API
enum UpdateChecker {
    
    static let currentVersion = "1.2.0"
    static let repoOwner = "WayneTechLab"
    static let repoName = "ClipperTube"
    
    struct Release: Codable {
        let tagName: String
        let name: String
        let htmlUrl: String
        let body: String?
        let publishedAt: String?
        let prerelease: Bool
        let draft: Bool
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlUrl = "html_url"
            case body
            case publishedAt = "published_at"
            case prerelease
            case draft
        }
    }
    
    struct UpdateInfo {
        var isUpdateAvailable: Bool
        var latestVersion: String
        var currentVersion: String
        var releaseURL: String
        var releaseNotes: String?
    }
    
    /// Check for updates against GitHub Releases
    static func checkForUpdates() async -> UpdateInfo? {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("CliperTube/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let release = try decoder.decode(Release.self, from: data)
            
            // Skip prereleases and drafts
            guard !release.prerelease && !release.draft else {
                return nil
            }
            
            let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
            let isNewer = compareVersions(current: currentVersion, latest: latestVersion)
            
            return UpdateInfo(
                isUpdateAvailable: isNewer,
                latestVersion: latestVersion,
                currentVersion: currentVersion,
                releaseURL: release.htmlUrl,
                releaseNotes: release.body
            )
            
        } catch {
            print("Update check failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Compare semantic version strings
    /// Returns true if latest is newer than current
    private static func compareVersions(current: String, latest: String) -> Bool {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(currentParts.count, latestParts.count)
        
        for i in 0..<maxLength {
            let currentPart = i < currentParts.count ? currentParts[i] : 0
            let latestPart = i < latestParts.count ? latestParts[i] : 0
            
            if latestPart > currentPart {
                return true
            } else if latestPart < currentPart {
                return false
            }
        }
        
        return false
    }
}
