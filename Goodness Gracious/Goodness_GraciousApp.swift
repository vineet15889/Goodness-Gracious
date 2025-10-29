//
//  Goodness_GraciousApp.swift
//  Goodness Gracious
//
//  Created by Vineet Rai on 29-Oct-25.
//

import SwiftUI
import UIKit

@main
struct Goodness_GraciousApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
