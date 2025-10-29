import Foundation

final class UploadViewModel: ObservableObject {
    @Published var isUploading: Bool = false
    @Published var errorMessage: String?
    @Published var success: Bool = false

    func uploadVideo(data: Data, caption: String?) {
        errorMessage = nil
        isUploading = true
        success = false
        Task { @MainActor in
            do {
                let fileName = "vid_\(UUID().uuidString).mp4"
                let url = try await StorageVideoService.shared.uploadVideo(data: data, fileName: fileName)
                let userId = AuthService.shared.currentUserId ?? "anonymous"
                try await FirestoreVideoService.shared.saveVideoMetadata(url: url, caption: caption, userId: userId)
                success = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }
}


