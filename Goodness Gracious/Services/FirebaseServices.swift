import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class AuthService {
    static let shared = AuthService()
    private init() {}

    var currentUserId: String? { Auth.auth().currentUser?.uid }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    // MARK: - Phone Auth
    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            // Ensure we have a valid provider instance
            let provider = PhoneAuthProvider.provider()
            
            // For test phone numbers like "9335922265", ensure proper formatting
            var formattedNumber = phoneNumber
            if !formattedNumber.hasPrefix("+") && formattedNumber.count == 10 {
                formattedNumber = "+91" + formattedNumber
            }
            
            provider.verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Handle the case where verificationID might be nil
                if let verificationID = verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing verification ID"]))
                }
            }
        }
    }

    func verifyCode(verificationId: String, code: String) async throws {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        _ = try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws { try Auth.auth().signOut() }
}

final class FirestoreVideoService {
    static let shared = FirestoreVideoService()
    private init() {}

    func fetchFeed(limit: Int = 20) async throws -> [VideoItem] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("videos")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            guard
                let urlString = doc["url"] as? String,
                let url = URL(string: urlString),
                let userId = doc["userId"] as? String,
                let ts = doc["createdAt"] as? TimeInterval
            else { return nil }
            return VideoItem(
                id: doc.documentID,
                url: url,
                userId: userId,
                caption: doc["caption"] as? String,
                createdAt: Date(timeIntervalSince1970: ts)
            )
        }
    }

    func saveVideoMetadata(url: URL, caption: String?, userId: String) async throws {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "url": url.absoluteString,
            "userId": userId,
            "caption": caption as Any,
            "createdAt": Date().timeIntervalSince1970
        ]
        _ = try await db.collection("videos").addDocument(data: data)
    }
}

final class StorageVideoService {
    static let shared = StorageVideoService()
    private init() {}

    func uploadVideo(data: Data, fileName: String) async throws -> URL {
        let storage = Storage.storage()
        let reference = storage.reference().child("videos/\(fileName)")
        
        // Create metadata with content type
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        // Set up background task identifier
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = await UIApplication.shared.beginBackgroundTask {
            // End the task if it expires
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        
        do {
            // Upload with metadata
            try await reference.putDataAsync(data, metadata: metadata)
            let url = try await reference.downloadURL()
            
            // End background task
            if backgroundTaskID != .invalid {
                await UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            return url
        } catch {
            // End background task on error
            if backgroundTaskID != .invalid {
                await UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            // Re-throw the error
            throw error
        }
    }
}


