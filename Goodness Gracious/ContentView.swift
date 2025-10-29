//
//  ContentView.swift
//  Goodness Gracious
//
//  Created by Vineet Rai on 29-Oct-25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainFeedView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(AuthViewModel())
}
