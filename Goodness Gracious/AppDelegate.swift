import Foundation
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase before using any Firebase services
        FirebaseApp.configure()
        
        #if DEBUG
        // Useful during development/simulator to avoid reCAPTCHA/APNs flow
        // This is critical for testing with test phone numbers
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        
        // For testing with the provided test number
        if let authDebugSettings = Auth.auth().settings {
            authDebugSettings.isAppVerificationDisabledForTesting = true
        }
        #endif
        
        return true
    }
}


