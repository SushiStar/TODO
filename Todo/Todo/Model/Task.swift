import Foundation

struct Task: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdDate: Date
    var completedDate: Date?
    var isCarriedOver: Bool

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        createdDate: Date = Calendar.current.startOfDay(for: Date()),
        completedDate: Date? = nil,
        isCarriedOver: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.isCarriedOver = isCarriedOver
    }
}
