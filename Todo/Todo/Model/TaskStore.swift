import Foundation

struct TaskStore: Codable {
    var tasks: [Task]
    var lastLaunchDate: Date

    init(tasks: [Task] = [], lastLaunchDate: Date = .distantPast) {
        self.tasks = tasks
        self.lastLaunchDate = lastLaunchDate
    }
}
