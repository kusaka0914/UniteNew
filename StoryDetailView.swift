import SwiftUI
import FirebaseFirestore

struct StoryDetailView: View {
    @State var currentIndex: Int
    @State var user: User

    @Binding var currentUser: User
    @State private var isHomeView: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var capturedImage: UIImage? // キャプチャした画像を保持する変数

    @State var stories: [Story] = []
    private var db = Firestore.firestore()

    init(stories: [Story], currentIndex: Int, user: User, currentUser: Binding<User>) {
        self.stories = stories
        self.currentIndex = currentIndex
        self.user = user
        self._currentUser = currentUser
    }

    var body: some View {
        VStack {
            headerView
            ProgressBar(progress: $progress)
                .frame(height: 4)
                .padding(.horizontal, 0)
                .background(Color.gray.opacity(0.5))
            storyTabView
            deleteButton
        }
        .background(Color.black)
        .onAppear {
            loadDataFromFirestore()
        }
        .overlay(
            capturedImage.map { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
        )
    }

    private var headerView: some View {
        HStack {
            HStack {
                Text("ストーリーズ")
                    .font(.headline)
                    .foregroundColor(.white)
                // Text(elapsedTimeString(since: stories[selectedIndex].postedDate))
                //     .font(.caption)
                //     .foregroundColor(.white)
            }
            Spacer()
            Button(action: {
                isHomeView = true
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
            .navigationDestination(isPresented: $isHomeView) {
                HomeView(currentUser: $currentUser, postUser: user)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .padding()
        .background(Color.black)
    }

    private var storyTabView: some View {
        TabView(selection: $currentIndex) {
            ForEach(stories, id: \.self) { story in
                    GeometryReader { geometry in
                        ZStack {
                            // storyImageView(for: story, geometry: geometry)
                            // storyTextsView(for: story)
                        }
                        .tag(story.id)
                        .onAppear {
                            startTimer()
                        }
                        .onDisappear {
                            stopTimer()
                        }
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .background(Color.black)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if value.startLocation.x < UIScreen.main.bounds.width / 2 {
                        goToPreviousStory()
                    } else {
                        goToNextStory()
                    }
                }
        )
    }

    private func goToPreviousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    private func goToNextStory() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if progress < 1.0 {
                progress += 0.01
            } else {
                timer?.invalidate()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
    }

    private func elapsedTimeString(since date: Date) -> String {
        let elapsedTime = Date().timeIntervalSince(date)
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var deleteButton: some View {
        Button(action: {
            deleteStory()
        }) {
            Text("削除")
                .foregroundColor(.white)
        }
    }
    
    private func deleteStory() {
        let storyToDelete = stories[currentIndex]
        if let index = currentUser.stories.firstIndex(where: { $0.id == storyToDelete.id }) {
            currentUser.stories.remove(at: index)
        }
        if let index = stories.firstIndex(where: { $0.id == storyToDelete.id }) {
            stories.remove(at: index)
        }
    }
    private func storyImageView(for story: Story, geometry: GeometryProxy) -> some View {
        Image(story.imageNames[currentIndex])
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(story.imageOffset)
            .scaleEffect(story.imageScale)
    }
    
//     private func storyTextsView(for story: Story) -> some View {
//     VStack {
//         ForEach(story.texts, id: \.self) { text in
//             Text(text.text)
//                 .font(.system(size: CGFloat(text.fontSize)))
//                 .foregroundColor(Color(text.color))
//                 .offset(x: text.position.x, y: text.position.y)
//         }
//     }
// }
    private func loadDataFromFirestore() {
        db.collection("users").document(user.id).collection("stories").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
       
            for document in documents {
                do {
                    let story = try document.data(as: Story.self)
                    stories.append(story)
                } catch {
                    print("Error decoding story: \(error)")
                }
            }
        }
    }
}

private struct ProgressBar: View {
    @Binding var progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray)
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
}
