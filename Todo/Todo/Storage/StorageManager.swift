import Foundation

final class StorageManager {
    static let shared = StorageManager()

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Todo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("tasks.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> TaskStore {
        guard let data = try? Data(contentsOf: fileURL) else { return TaskStore() }
        return (try? decoder.decode(TaskStore.self, from: data)) ?? TaskStore()
    }

    func save(_ store: TaskStore) {
        guard let data = try? encoder.encode(store) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
