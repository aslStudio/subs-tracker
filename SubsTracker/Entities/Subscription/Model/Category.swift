import Foundation
import SwiftData

@Model
final class CategoryItem {
    var id: UUID
    var title: String
    var color: String
    
    init(
        id: UUID = UUID(),
        title: String,
        color: String,
    ) {
        self.id = id
        self.title = title
        self.color = color
    }
}
