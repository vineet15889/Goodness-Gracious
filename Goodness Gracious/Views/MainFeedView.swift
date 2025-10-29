import SwiftUI
import AVKit

struct MainFeedView: View {
    @StateObject private var feed = FeedViewModel()
    @State private var showRecorder = false
    @State private var showProfile = false
    @StateObject private var uploader = UploadViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var currentVideoIndex = 0
    @State private var players: [Int: AVPlayer] = [:]
    @State private var showComments = false
    @State private var commentText = ""
    
    var body: some View {
        ZStack {
            // Main content
            if feed.isLoading && feed.videos.isEmpty {
                loadingView
            } else if !feed.videos.isEmpty {
                videoFeedView
            } else {
                emptyStateView
            }
            
            // Floating buttons
            VStack {
                // Profile button at top right
                HStack {
                    Spacer()
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(.top, 50)
                            .padding(.trailing, 20)
                    }
                }
                
                Spacer()
                
                // Record button at bottom right
                HStack {
                    Button(action: { showRecorder = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .shadow(radius: 6)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                    Spacer()
                }
            }
            
            // Upload overlay
            if uploader.isUploading {
                uploadingOverlay
            }
            
            // Comment sheet
            if showComments {
                commentOverlay
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task { feed.loadFeed() }
        .onChange(of: uploader.success) { success in
            if success {
                // Auto-refresh feed and reset success state after upload
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
                    uploader.success = false
                    feed.loadFeed()
                }
            }
        }
        .sheet(isPresented: $showRecorder) {
            VideoCaptureView(maxDuration: 15) { result in
                switch result {
                case .success(let recording):
                    if let data = try? Data(contentsOf: recording.fileURL) {
                        uploader.uploadVideo(data: data, caption: nil)
                    }
                case .failure:
                    break
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            profileView
        }
    }
    
    // MARK: - Component Views
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text("Loading videos...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView("No Videos Yet", systemImage: "video.slash", description: Text("Be the first to upload a video!"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
    
    private var videoFeedView: some View {
        GeometryReader { geometry in
            TabView(selection: $currentVideoIndex) {
                ForEach(Array(feed.videos.enumerated()), id: \.element.id) { index, video in
                    ZStack {
                        // Video player
                        VideoPlayerView(player: playerFor(index: index), geometry: geometry)
                            .onAppear {
                                if currentVideoIndex == index {
                                    playerFor(index: index).play()
                                }
                            }
                            .onDisappear {
                                playerFor(index: index).pause()
                            }
                        
                        // Video controls overlay
                        VStack {
                            Spacer()
                            
                            // Bottom controls
                            HStack(alignment: .bottom) {
                                // Caption and user info
                                VStack(alignment: .leading, spacing: 8) {
                                    if let caption = video.caption {
                                        Text(caption)
                                            .font(.callout)
                                            .foregroundStyle(.white)
                                            .lineLimit(2)
                                    }
                                    Text("@\(video.userId.prefix(8))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(.leading)
                                .padding(.bottom, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Reaction buttons
                                VStack(spacing: 20) {
                                    Button(action: {}) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(.white)
                                            Text("Like")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    
                                    Button(action: { showComments = true }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "bubble.right.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(.white)
                                            Text("Comment")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .padding(.trailing)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: currentVideoIndex) { newIndex in
                // Pause all videos except current
                players.forEach { index, player in
                    if index == newIndex {
                        player.play()
                    } else {
                        player.pause()
                    }
                }
            }
        }
        .background(Color.black)
    }
    
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                Text(uploader.success ? "Uploaded!" : "Uploading...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 12)
        }
        .transition(.opacity)
    }
    
    private var commentOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showComments = false
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Comment header
                    HStack {
                        Text("Comments")
                            .font(.headline)
                        Spacer()
                        Button(action: { showComments = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    // Comment list (placeholder)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(1...5, id: \.self) { i in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("User\(i)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("This is a sample comment \(i). Comments would be loaded from a database.")
                                            .font(.callout)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Comment input
                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .padding(10)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(20)
                        
                        Button(action: {
                            // Add comment functionality would go here
                            commentText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title3)
                        }
                        .disabled(commentText.isEmpty)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
                .frame(height: 400)
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
        .transition(.move(edge: .bottom))
    }
    
    private var profileView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                    
                    Text("User Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(auth.phoneNumber)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Sign out button
                Button(action: { auth.signOut() }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showProfile = false }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func playerFor(index: Int) -> AVPlayer {
        if let player = players[index] {
            return player
        } else {
            let player = AVPlayer(url: feed.videos[index].url)
            player.actionAtItemEnd = .none
            players[index] = player
            return player
        }
    }
}

// MARK: - Supporting Views

struct VideoPlayerView: View {
    let player: AVPlayer
    let geometry: GeometryProxy
    
    var body: some View {
        VideoPlayer(player: player)
            .disabled(true) // Disable default controls
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                // Loop video
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
            }
    }
}


