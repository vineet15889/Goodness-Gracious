import Foundation

final class FeedViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadFeed() {
        isLoading = true
        errorMessage = nil
        Task { @MainActor in
            do {
                let items = try await FirestoreVideoService.shared.fetchFeed()
                videos = items
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}


