import AppKit
import Foundation
import Security

struct YouTubeChannelInfo: Identifiable {
    var id: String
    var title: String
    var handle: String?
    var subscriberCount: String?
}

struct YouTubeVideoInfo: Identifiable {
    var id: String
    var title: String
    var publishedAt: Date?
    var thumbnailURL: String?

    var watchURL: URL {
        URL(string: "https://www.youtube.com/watch?v=\(id)")!
    }
}

enum YouTubePrivacyStatus: String, CaseIterable, Identifiable {
    case privateVideo = "private"
    case unlisted
    case publicVideo = "public"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .privateVideo: return "Private"
        case .unlisted: return "Unlisted"
        case .publicVideo: return "Public"
        }
    }
}

@MainActor
final class YouTubeStore: ObservableObject {
    @Published var clientID: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var isBusy: Bool = false
    @Published var statusMessage: String = "Configure OAuth client ID to connect YouTube."
    @Published var lastError: String?
    @Published var verificationURL: String?
    @Published var verificationCode: String?
    @Published var channels: [YouTubeChannelInfo] = []
    @Published var selectedChannelID: String?
    @Published var recentVideos: [YouTubeVideoInfo] = []
    @Published var browserQuery: String = ""
    @Published var browserVideos: [YouTubeVideoInfo] = []
    @Published var selectedPreviewVideoID: String?
    @Published var lastUploadedVideoID: String?

    private let fileManager = FileManager.default
    private let keychainService = "com.waynetechlab.clipertube.youtube"
    private let keychainAccount = "oauth_tokens"

    private var token: OAuthTokens? {
        didSet {
            isAuthenticated = token != nil
        }
    }

    private lazy var appSupportDirectory: URL = {
        let home = fileManager.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("CliperTube", isDirectory: true)
    }()

    private var configURL: URL {
        appSupportDirectory.appendingPathComponent("youtube_config.json")
    }

    init() {
        loadConfig()
        loadStoredTokens()

        if token != nil {
            Task {
                await refreshChannelsAndVideos()
            }
        }
    }

    func saveClientID() {
        let clean = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.isEmpty == false else {
            lastError = "OAuth client ID cannot be empty."
            return
        }
        guard clean.contains(".apps.googleusercontent.com") else {
            lastError = "OAuth client ID should end with .apps.googleusercontent.com."
            return
        }
        clientID = clean
        persistConfig()
        statusMessage = "YouTube OAuth client ID saved."
    }

    func connectYouTube() {
        guard isBusy == false else { return }
        Task {
            await runDeviceAuthFlow()
        }
    }

    func signOut() {
        token = nil
        channels = []
        recentVideos = []
        selectedChannelID = nil
        verificationURL = nil
        verificationCode = nil
        lastUploadedVideoID = nil
        removeStoredTokens()
        persistConfig()
        statusMessage = "YouTube account disconnected."
    }

    func refreshChannelsAndVideos() async {
        guard token != nil else {
            statusMessage = "Sign in to YouTube first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            try await loadChannels()
            try await loadRecentVideos()
            statusMessage = "YouTube channels and videos refreshed."
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Failed to refresh YouTube data."
        }
    }

    func setSelectedChannel(_ channelID: String) {
        selectedChannelID = channelID
        persistConfig()

        Task {
            do {
                try await loadRecentVideos()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func openVerificationURL() {
        guard let urlString = verificationURL,
              let url = URL(string: urlString) else {
            lastError = "Verification URL is not available."
            return
        }
        if NSWorkspace.shared.open(url) == false {
            lastError = "Could not open verification URL."
        }
    }

    func openVideo(_ video: YouTubeVideoInfo) {
        NSWorkspace.shared.open(video.watchURL)
    }

    func searchBrowserVideos() {
        guard isBusy == false else { return }
        Task {
            await runBrowserSearch()
        }
    }

    func selectPreviewVideo(_ videoID: String) {
        selectedPreviewVideoID = videoID
    }

    var selectedPreviewVideo: YouTubeVideoInfo? {
        if let selectedPreviewVideoID {
            return browserVideos.first(where: { $0.id == selectedPreviewVideoID })
                ?? recentVideos.first(where: { $0.id == selectedPreviewVideoID })
        }
        return browserVideos.first ?? recentVideos.first
    }

    func embedURL(for videoID: String) -> URL? {
        var components = URLComponents(string: "https://www.youtube.com/embed/\(videoID)")
        components?.queryItems = [
            .init(name: "playsinline", value: "1"),
            .init(name: "autoplay", value: "0"),
            .init(name: "rel", value: "0"),
            .init(name: "modestbranding", value: "1")
        ]
        return components?.url
    }

    func openUploadedVideo(videoID: String) {
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func uploadVideo(filePath: String, title: String, description: String, privacy: YouTubePrivacyStatus) {
        guard isBusy == false else { return }
        Task {
            await uploadVideoInternal(filePath: filePath, title: title, description: description, privacy: privacy)
        }
    }

    private func runDeviceAuthFlow() async {
        let cleanID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanID.isEmpty == false else {
            lastError = "Enter and save your Google OAuth client ID first."
            return
        }

        isBusy = true
        lastError = nil
        statusMessage = "Requesting YouTube device code..."

        do {
            let deviceCode = try await requestDeviceCode(clientID: cleanID)
            verificationURL = deviceCode.verificationURL
            verificationCode = deviceCode.userCode
            statusMessage = "Open verification URL and enter code: \(deviceCode.userCode)"
            openVerificationURL()

            let tokens = try await pollForTokens(deviceCode: deviceCode, clientID: cleanID)
            token = tokens
            persistTokens(tokens)
            verificationURL = nil
            verificationCode = nil
            statusMessage = "YouTube connected successfully."
            persistConfig()
            try await loadChannels()
            try await loadRecentVideos()
        } catch is CancellationError {
            lastError = nil
            statusMessage = "YouTube sign-in cancelled."
        } catch {
            lastError = error.localizedDescription
            statusMessage = "YouTube sign-in failed."
        }

        isBusy = false
    }

    private func uploadVideoInternal(filePath: String, title: String, description: String, privacy: YouTubePrivacyStatus) async {
        let cleanPath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanPath.isEmpty == false else {
            lastError = "Select a rendered video first."
            return
        }

        let url = URL(fileURLWithPath: cleanPath)
        guard fileManager.fileExists(atPath: url.path) else {
            lastError = "Rendered file not found: \(cleanPath)"
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanTitle.isEmpty == false else {
            lastError = "Video title is required for YouTube upload."
            return
        }

        isBusy = true
        lastError = nil
        statusMessage = "Preparing YouTube upload..."

        do {
            statusMessage = "Creating YouTube upload session..."
            let uploadURL = try await createResumableUploadSession(
                fileURL: url,
                title: cleanTitle,
                description: description,
                privacy: privacy
            )

            statusMessage = "Uploading video to YouTube..."
            let videoID = try await uploadVideoBinary(uploadURL: uploadURL, fileURL: url)
            lastUploadedVideoID = videoID
            statusMessage = "Upload complete. Video ID: \(videoID)"
            do {
                try await loadRecentVideos()
            } catch {
                statusMessage = "Upload complete. Video ID: \(videoID). Recent list refresh failed."
            }
        } catch is CancellationError {
            lastError = nil
            statusMessage = "YouTube upload cancelled."
        } catch {
            lastError = error.localizedDescription
            statusMessage = "YouTube upload failed."
        }

        isBusy = false
    }

    private func loadChannels() async throws {
        let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true")!
        let (data, _) = try await authorizedRequest(url: url)

        let response = try JSONDecoder().decode(ChannelListResponse.self, from: data)
        channels = response.items.map { item in
            YouTubeChannelInfo(
                id: item.id,
                title: item.snippet.title,
                handle: item.snippet.customURL,
                subscriberCount: item.statistics?.subscriberCount
            )
        }

        if let selectedChannelID,
           channels.contains(where: { $0.id == selectedChannelID }) {
            // Keep current selection
        } else {
            selectedChannelID = channels.first?.id
        }

        persistConfig()
    }

    private func loadRecentVideos() async throws {
        guard let channelID = selectedChannelID else {
            recentVideos = []
            return
        }

        recentVideos = try await fetchVideos(channelID: channelID, query: nil, maxResults: 20, order: "date")

        if selectedPreviewVideoID == nil,
           let firstID = recentVideos.first?.id {
            selectedPreviewVideoID = firstID
        }
    }

    private func runBrowserSearch() async {
        guard token != nil else {
            lastError = "Connect YouTube before searching videos."
            return
        }

        let query = browserQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else {
            lastError = "Enter a search query to find videos."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            browserVideos = try await fetchVideos(channelID: nil, query: query, maxResults: 24, order: "relevance")
            if let firstID = browserVideos.first?.id {
                selectedPreviewVideoID = firstID
            }
            statusMessage = "Search returned \(browserVideos.count) video(s)."
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            statusMessage = "YouTube search failed."
        }
    }

    private func fetchVideos(
        channelID: String?,
        query: String?,
        maxResults: Int,
        order: String
    ) async throws -> [YouTubeVideoInfo] {
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "maxResults", value: String(max(1, min(maxResults, 50)))),
            .init(name: "order", value: order),
            .init(name: "type", value: "video")
        ]

        if let channelID, channelID.isEmpty == false {
            queryItems.append(.init(name: "channelId", value: channelID))
        }

        if let query, query.isEmpty == false {
            queryItems.append(.init(name: "q", value: query))
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = queryItems

        let (data, _) = try await authorizedRequest(url: components.url!)
        let response = try JSONDecoder().decode(VideoSearchResponse.self, from: data)

        let formatter = ISO8601DateFormatter()
        return response.items.compactMap { item in
            guard let videoID = item.id.videoID else { return nil }
            return YouTubeVideoInfo(
                id: videoID,
                title: item.snippet.title,
                publishedAt: formatter.date(from: item.snippet.publishedAt),
                thumbnailURL: item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.defaultThumb?.url
            )
        }
    }

    private func createResumableUploadSession(
        fileURL: URL,
        title: String,
        description: String,
        privacy: YouTubePrivacyStatus
    ) async throws -> URL {
        var components = URLComponents(string: "https://www.googleapis.com/upload/youtube/v3/videos")!
        components.queryItems = [
            .init(name: "uploadType", value: "resumable"),
            .init(name: "part", value: "snippet,status")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        let fileSize = (try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        request.setValue("\(fileSize)", forHTTPHeaderField: "X-Upload-Content-Length")
        request.setValue(mimeType(for: fileURL), forHTTPHeaderField: "X-Upload-Content-Type")

        let metadata = VideoInsertRequest(
            snippet: .init(
                title: title,
                description: description,
                categoryID: "22"
            ),
            status: .init(privacyStatus: privacy.rawValue)
        )
        request.httpBody = try JSONEncoder().encode(metadata)

        let (_, http) = try await authorizedDataRequest(request)

        guard let location = http.value(forHTTPHeaderField: "Location"),
              let uploadURL = URL(string: location) else {
            throw YouTubeError.uploadSessionMissing
        }

        return uploadURL
    }

    private func uploadVideoBinary(uploadURL: URL, fileURL: URL) async throws -> String {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue(mimeType(for: fileURL), forHTTPHeaderField: "Content-Type")

        let (data, _) = try await authorizedUploadRequest(request, fromFile: fileURL)

        let result = try JSONDecoder().decode(VideoInsertResponse.self, from: data)
        return result.id
    }

    private func requestDeviceCode(clientID: String) async throws -> DeviceCodeResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let scope = [
            "https://www.googleapis.com/auth/youtube.readonly",
            "https://www.googleapis.com/auth/youtube.upload"
        ].joined(separator: " ")

        request.httpBody = formEncoded([
            "client_id": clientID,
            "scope": scope
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw parseErrorResponse(data: data, statusCode: http.statusCode)
        }

        return try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
    }

    private func pollForTokens(deviceCode: DeviceCodeResponse, clientID: String) async throws -> OAuthTokens {
        let expiresAt = Date().addingTimeInterval(TimeInterval(deviceCode.expiresIn))
        var interval = max(5, deviceCode.interval ?? 5)

        while Date() < expiresAt {
            if Task.isCancelled {
                throw CancellationError()
            }
            try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)

            var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = formEncoded([
                "client_id": clientID,
                "device_code": deviceCode.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw YouTubeError.invalidResponse
            }

            if (200...299).contains(http.statusCode) {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                let expiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
                return OAuthTokens(
                    accessToken: tokenResponse.accessToken,
                    refreshToken: tokenResponse.refreshToken,
                    expiresAt: expiry,
                    tokenType: tokenResponse.tokenType,
                    scope: tokenResponse.scope
                )
            }

            if let payload = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                switch payload.error {
                case "authorization_pending":
                    continue
                case "slow_down":
                    interval += 5
                    continue
                case "access_denied":
                    throw YouTubeError.auth("Authorization was denied.")
                case "expired_token":
                    throw YouTubeError.auth("The device code expired before authorization finished.")
                default:
                    throw YouTubeError.auth(payload.errorDescription ?? payload.error)
                }
            }

            throw YouTubeError.httpStatus(http.statusCode)
        }

        throw YouTubeError.auth("Authorization timed out. Start sign-in again.")
    }

    private func validAccessToken() async throws -> String {
        guard let token else {
            throw YouTubeError.auth("You are not authenticated with YouTube.")
        }

        if token.expiresAt > Date().addingTimeInterval(60) {
            return token.accessToken
        }

        return try await refreshAccessToken(using: token)
    }

    private func refreshAccessToken(using oldToken: OAuthTokens) async throws -> String {
        guard let refreshToken = oldToken.refreshToken,
              refreshToken.isEmpty == false else {
            throw YouTubeError.auth("Missing refresh token. Sign in again.")
        }

        let cleanID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanID.isEmpty == false else {
            throw YouTubeError.auth("OAuth client ID is missing.")
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncoded([
            "client_id": cleanID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw parseErrorResponse(data: data, statusCode: http.statusCode)
        }

        let refreshed = try JSONDecoder().decode(TokenResponse.self, from: data)
        let merged = OAuthTokens(
            accessToken: refreshed.accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(refreshed.expiresIn)),
            tokenType: refreshed.tokenType,
            scope: refreshed.scope ?? oldToken.scope
        )

        token = merged
        persistTokens(merged)
        return merged.accessToken
    }

    private func authorizedRequest(url: URL) async throws -> (Data, HTTPURLResponse) {
        let request = URLRequest(url: url)
        return try await authorizedDataRequest(request)
    }

    private func authorizedDataRequest(_ baseRequest: URLRequest, retryOnUnauthorized: Bool = true) async throws -> (Data, HTTPURLResponse) {
        var request = baseRequest
        request.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeError.invalidResponse
        }

        if http.statusCode == 401, retryOnUnauthorized, let token {
            _ = try await refreshAccessToken(using: token)
            return try await authorizedDataRequest(baseRequest, retryOnUnauthorized: false)
        }

        guard (200...299).contains(http.statusCode) else {
            throw parseErrorResponse(data: data, statusCode: http.statusCode)
        }

        return (data, http)
    }

    private func authorizedUploadRequest(
        _ baseRequest: URLRequest,
        fromFile fileURL: URL,
        retryOnUnauthorized: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        var request = baseRequest
        request.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeError.invalidResponse
        }

        if http.statusCode == 401, retryOnUnauthorized, let token {
            _ = try await refreshAccessToken(using: token)
            return try await authorizedUploadRequest(baseRequest, fromFile: fileURL, retryOnUnauthorized: false)
        }

        guard (200...299).contains(http.statusCode) else {
            throw parseErrorResponse(data: data, statusCode: http.statusCode)
        }

        return (data, http)
    }

    private func parseErrorResponse(data: Data, statusCode: Int) -> YouTubeError {
        if let payload = try? JSONDecoder().decode(YouTubeAPIErrorResponse.self, from: data) {
            return .api(payload.error.message)
        }
        if let payload = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
            return .auth(payload.errorDescription ?? payload.error)
        }
        return .httpStatus(statusCode)
    }

    private func mimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "mp4": return "video/mp4"
        case "m4v": return "video/x-m4v"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }

    private func formEncoded(_ values: [String: String]) -> Data {
        let encoded = values
            .map { key, value in
                "\(key.urlEncoded)=\(value.urlEncoded)"
            }
            .joined(separator: "&")

        return Data(encoded.utf8)
    }

    private func loadConfig() {
        do {
            try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)

            guard fileManager.fileExists(atPath: configURL.path) else { return }
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(YouTubeConfig.self, from: data)
            clientID = config.clientID
            selectedChannelID = config.selectedChannelID
        } catch {
            lastError = "Failed to load YouTube config: \(error.localizedDescription)"
        }
    }

    private func persistConfig() {
        do {
            try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
            let config = YouTubeConfig(clientID: clientID, selectedChannelID: selectedChannelID)
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL, options: [.atomic])
        } catch {
            lastError = "Failed to save YouTube config: \(error.localizedDescription)"
        }
    }

    private func loadStoredTokens() {
        do {
            guard let data = try keychainRead(service: keychainService, account: keychainAccount) else {
                token = nil
                return
            }

            token = try JSONDecoder().decode(OAuthTokens.self, from: data)
        } catch {
            token = nil
            lastError = "Failed to read stored YouTube token securely."
        }
    }

    private func persistTokens(_ tokens: OAuthTokens) {
        do {
            let data = try JSONEncoder().encode(tokens)
            try keychainWrite(service: keychainService, account: keychainAccount, data: data)
        } catch {
            lastError = "Failed to store YouTube token securely."
        }
    }

    private func removeStoredTokens() {
        do {
            try keychainDelete(service: keychainService, account: keychainAccount)
        } catch {
            lastError = "Failed to clear stored YouTube token."
        }
    }

    private func keychainWrite(service: String, account: String, data: Data) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let addQuery: [String: Any] = baseQuery.merging([
            kSecValueData as String: data
        ]) { _, new in new }

        let deleteStatus = SecItemDelete(baseQuery as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.deleteFailed(deleteStatus)
        }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.writeFailed(addStatus)
        }
    }

    private func keychainRead(service: String, account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.readFailed(status)
        }

        return result as? Data
    }

    private func keychainDelete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

private struct YouTubeConfig: Codable {
    var clientID: String
    var selectedChannelID: String?
}

private struct OAuthTokens: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
    var tokenType: String
    var scope: String?
}

private struct DeviceCodeResponse: Decodable {
    var deviceCode: String
    var userCode: String
    var verificationURL: String
    var expiresIn: Int
    var interval: Int?

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURL = "verification_url"
        case verificationURI = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceCode = try container.decode(String.self, forKey: .deviceCode)
        userCode = try container.decode(String.self, forKey: .userCode)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval)

        if let url = try container.decodeIfPresent(String.self, forKey: .verificationURL) {
            verificationURL = url
        } else if let uri = try container.decodeIfPresent(String.self, forKey: .verificationURI) {
            verificationURL = uri
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.verificationURL,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing verification URL in device code response."
                )
            )
        }
    }
}

private struct TokenResponse: Decodable {
    var accessToken: String
    var expiresIn: Int
    var refreshToken: String?
    var tokenType: String
    var scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case scope
    }
}

private struct OAuthErrorResponse: Decodable {
    var error: String
    var errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

private struct ChannelListResponse: Decodable {
    struct Item: Decodable {
        struct Snippet: Decodable {
            var title: String
            var customURL: String?

            enum CodingKeys: String, CodingKey {
                case title
                case customURL = "customUrl"
            }
        }

        struct Statistics: Decodable {
            var subscriberCount: String?
        }

        var id: String
        var snippet: Snippet
        var statistics: Statistics?
    }

    var items: [Item]
}

private struct VideoSearchResponse: Decodable {
    struct Item: Decodable {
        struct ID: Decodable {
            var videoID: String?

            enum CodingKeys: String, CodingKey {
                case videoID = "videoId"
            }
        }

        struct Snippet: Decodable {
            struct Thumbnails: Decodable {
                struct Thumbnail: Decodable {
                    var url: String
                }

                var defaultThumb: Thumbnail?
                var medium: Thumbnail?

                enum CodingKeys: String, CodingKey {
                    case defaultThumb = "default"
                    case medium
                }
            }

            var title: String
            var publishedAt: String
            var thumbnails: Thumbnails
        }

        var id: ID
        var snippet: Snippet
    }

    var items: [Item]
}

private struct VideoInsertRequest: Encodable {
    struct Snippet: Encodable {
        var title: String
        var description: String
        var categoryID: String

        enum CodingKeys: String, CodingKey {
            case title
            case description
            case categoryID = "categoryId"
        }
    }

    struct Status: Encodable {
        var privacyStatus: String
    }

    var snippet: Snippet
    var status: Status
}

private struct VideoInsertResponse: Decodable {
    var id: String
}

private struct YouTubeAPIErrorResponse: Decodable {
    struct WrappedError: Decodable {
        var message: String
    }

    var error: WrappedError
}

private enum YouTubeError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case auth(String)
    case api(String)
    case uploadSessionMissing

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from YouTube."
        case .httpStatus(let code):
            return "YouTube request failed with HTTP \(code)."
        case .auth(let message):
            return message
        case .api(let message):
            return message
        case .uploadSessionMissing:
            return "YouTube upload session could not be created."
        }
    }
}

private enum KeychainError: LocalizedError {
    case writeFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let status):
            return "Keychain write failed (\(status))."
        case .readFailed(let status):
            return "Keychain read failed (\(status))."
        case .deleteFailed(let status):
            return "Keychain delete failed (\(status))."
        }
    }
}

private extension String {
    var urlEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
