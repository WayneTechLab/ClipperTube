import Foundation

struct ExportManifest: Codable {
    var generatedAt: Date
    var projectTitle: String
    var videoID: String
    var preset: ExportPreset
    var clipCount: Int
    var captionCount: Int
    var voiceOverCount: Int
    var clips: [ClipSegment]
    var captions: [CaptionSegment]
    var voiceOvers: [VoiceOverSegment]
    var editor: EditorSettings
}

final class ProjectPersistence {
    private let fileManager = FileManager.default

    private lazy var appSupportDirectory: URL = {
        let home = fileManager.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("CliperTube", isDirectory: true)
    }()

    private var workspaceFileURL: URL {
        appSupportDirectory.appendingPathComponent("workspace.json")
    }

    private var legacyProjectFileURL: URL {
        appSupportDirectory.appendingPathComponent("project.json")
    }

    func save(workspace: ProjectWorkspace) throws {
        try ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(workspace)
        try data.write(to: workspaceFileURL, options: [.atomic])
    }

    func loadWorkspace() throws -> ProjectWorkspace {
        try ensureDirectories()

        if fileManager.fileExists(atPath: workspaceFileURL.path) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: workspaceFileURL)
            return try decoder.decode(ProjectWorkspace.self, from: data)
        }

        if fileManager.fileExists(atPath: legacyProjectFileURL.path) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: legacyProjectFileURL)
            var project = try decoder.decode(StudioProject.self, from: data)
            project.status = .current

            let migrated = ProjectWorkspace(
                schemaVersion: 1,
                activeProjectID: project.id,
                projects: [project]
            )
            try save(workspace: migrated)
            return migrated
        }

        return .empty
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
    }
}
