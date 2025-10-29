import SwiftUI
import UIKit
import AVFoundation

struct VideoRecordingResult {
    let fileURL: URL
}

struct VideoCaptureView: UIViewControllerRepresentable {
    let maxDuration: TimeInterval
    let completion: (Result<VideoRecordingResult, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(maxDuration: maxDuration, completion: completion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = maxDuration
        picker.cameraCaptureMode = .video
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let maxDuration: TimeInterval
        let completion: (Result<VideoRecordingResult, Error>) -> Void

        init(maxDuration: TimeInterval, completion: @escaping (Result<VideoRecordingResult, Error>) -> Void) {
            self.maxDuration = maxDuration
            self.completion = completion
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { picker.dismiss(animated: true) }
            guard let url = info[.mediaURL] as? URL else { return }
            completion(.success(.init(fileURL: url)))
        }
    }
}


