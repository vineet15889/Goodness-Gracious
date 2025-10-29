import Foundation

struct VideoItem: Identifiable, Hashable {
    let id: String
    let url: URL
    let userId: String
    let caption: String?
    let createdAt: Date
}


