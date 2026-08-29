import Foundation

public enum FileNameGenerator {
    public static func destinationURL(for sourceURL: URL, fileManager: FileManager = .default) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let stem = sourceURL.deletingPathExtension().lastPathComponent + "_compressed"
        var candidate = directory.appendingPathComponent(stem).appendingPathExtension("jpg")
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(stem)_\(suffix)").appendingPathExtension("jpg")
            suffix += 1
        }
        return candidate
    }
}
