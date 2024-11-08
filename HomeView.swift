import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct HomeView: View {
    @State private var users: [User] = []
    @Binding var currentUser: User
    @State var goodcount: Int?
    @State private var selectedStory: Story?
    @State private var selectedUser: User?
    @State private var postUser: User
    @State private var isStoryDetailViewActive = false
    @State private var isSearchViewActive = false
    @State private var isUserProfileViewActive = false
    @State private var isCreateStoryViewActive = false
    @State private var isNotificationViewActive = false
    @State private var selectedPost: Post?
    @State private var isPostDetailViewActive = false
    @State private var showAlert = false
    @State private var isAllMessageViewActive = false
    @State private var isRankingBoardViewActive = false
    @State private var isEverythingBoardViewActive = false
    @State private var isBulltinBoardViewActive = false
    @State private var isAnotherUserProfileViewActive = false
    @State private var isLoading = true
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, postUser: User) {
        self._currentUser = currentUser
        self.postUser = postUser
    }

    var body: some View {
        if isLoading {
            ProgressView()
            .onAppear {
                loadUsers()
                loadCurrentUser()
            }
        } else {
        // NavigationStack {
            VStack {
                headerView()
                storyScrollView()
                if users.count > 0 {
                    postListView()
                }
                Spacer()
                navigationBar()
            }
            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                        AnotherUserProfileView(user: $postUser, currentUser: $currentUser)
                            .navigationBarBackButtonHidden(true)
                    }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationDestination(isPresented: $isStoryDetailViewActive) {
                if let selectedStory = selectedStory, let selectedUser = selectedUser {
                    StoryDetailView(stories: currentUser.stories, currentIndex: 0, user: currentUser, currentUser: $currentUser)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -100 {
                            isAllMessageViewActive = true
                        }
                    }
            )
        // }
        .background(Color.black)
        .foregroundColor(.white)
        
        }
    }

    private func headerView() -> some View {
        HStack {
            HStack {
                Image("Sphere")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Unite")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(.leading, 30)
            Spacer()
            HStack {
                Button(action: {
                    isRankingBoardViewActive = true
                }) {
                    Image("ranking")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 10)
                }
                .navigationDestination(isPresented: $isRankingBoardViewActive) {
                    RankingBoardView(user: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [], everythingBoards: [], points: 0), currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                Button(action: {
                    isEverythingBoardViewActive = true
                }) {
                    Image("board")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 10)
                }
                .navigationDestination(isPresented: $isEverythingBoardViewActive) {
                    EverythingBoardView(currentUser: $currentUser, user: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], everythingBoards: [], points: 0))
                        .navigationBarBackButtonHidden(true)
                }
                Button(action: {
                    isBulltinBoardViewActive = true
                }) {
                    Image("shake")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 10)
                }
                .navigationDestination(isPresented: $isBulltinBoardViewActive) {
                    BulltinBoardView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                Button(action: {
                    isNotificationViewActive = true
                }) {
                    ZStack {
                        Image("bell")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding(.trailing, 10)
                        if currentUser.notifications.filter { !$0.isRead }.count > 0 {
                            Text("\(currentUser.notifications.filter { !$0.isRead }.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .navigationDestination(isPresented: $isNotificationViewActive) {
                    NotificationListView(currentUserId: $currentUser.id, selectedUser: selectedUser ?? User(id: "", password: "password", username: "currentUser", university: "University", posts: [], texts: [], followers: [], following: [], accountname: "accountname", faculty: "faculty", department: "department", club: "club", bio: "bio", twitterHandle: "twitterHandle", email: "email", stories: [], iconImageURL: "https://firebasestorage.googleapis.com/v0/b/splean-app.appspot.com/o/userIcons%2F1.jpg?alt=media&token=12345678-1234-5678-1234-567812345678", notifications: [], messages: [], groupMessages: []))
                        .navigationBarBackButtonHidden(true)
                }
                Button(action: {
                    isAllMessageViewActive = true
                }) {
                    ZStack {
                        Image("DM")
                            .resizable()
                            .frame(width: 30, height: 30)
                        if currentUser.unreadMessagesCount() > 0 {
                            Text("\(currentUser.unreadMessagesCount())")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .navigationDestination(isPresented: $isAllMessageViewActive) {
                    AllMessageView(currentUserId: $currentUser.id)
                        .navigationBarBackButtonHidden(true)
                }
            }.padding()
        }
    }

        private func storyScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                if let firstStory = currentUser.stories.first {
                    Button(action: {
                        selectedStory = firstStory
                        selectedUser = currentUser
                        isStoryDetailViewActive = true
                    }) {
                        StoryView(story: firstStory, user: currentUser, currentUser: $currentUser)
                    }
                } else {
                    Button(action: {
                        isCreateStoryViewActive = true
                    }) {
                        VStack {
                            Button(action: {
                                isCreateStoryViewActive = true
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                    Text("Create Story")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }.navigationDestination(isPresented: $isCreateStoryViewActive) {
                                CreateStoryView(currentUser: $currentUser, onStoryCreated: { newStory in
                                    currentUser.stories.append(newStory)
                                })
                                .navigationBarBackButtonHidden(true)
                            }
                        }
                    }.navigationDestination(isPresented: $isStoryDetailViewActive) {
                        StoryDetailView(stories: currentUser.stories, currentIndex: 0, user: currentUser, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                    }
                }

                ForEach(users.filter { user in
                    currentUser.following.contains(user.id)
                }) { user in
                    if let firstStory = user.stories.first {
                        Button(action: {
                            selectedStory = firstStory
                            selectedUser = user
                            isStoryDetailViewActive = true
                        }) {
                            StoryView(story: firstStory, user: user, currentUser: $currentUser)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func postListView() -> some View {
        
        ScrollView  {
            ForEach(users.filter { user in
                currentUser.following.contains(user.id)
            }.flatMap { $0.posts }.sorted(by: { $0.date > $1.date })) { post in
                if let postUser = users.first(where: { $0.posts.contains(where: { $0.id == post.id }) }) {
                    postListItemView(post: post, postUser: postUser)
                }
            }
        }
    }

    private func postListItemView(post: Post, postUser: User) -> some View {
        VStack(alignment: .leading) {
            HStack {
                if let iconImageURL = postUser.iconImageURL, let url = URL(string: iconImageURL) {
                    WebImage(url: url)
                        .resizable()
                        .onFailure { error in
                            ProgressView()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .padding(.leading, 16)
                        .onTapGesture {
                            self.postUser = postUser
                            isAnotherUserProfileViewActive = true
                        }
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .padding(.leading, 16)
                        .onTapGesture {
                            self.postUser = postUser
                            isAnotherUserProfileViewActive = true
                        }
                }
                Text(postUser.username)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .onTapGesture {
                        self.postUser = postUser
                        isAnotherUserProfileViewActive = true
                    }
                Spacer()
            }
            .padding(.top, 16)

            if !post.imageUrls.isEmpty {
                TabView {
                    ForEach(post.imageUrls, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .onFailure { error in
                                    ProgressView()
                                        .frame(maxWidth: UIScreen.main.bounds.width)
                                }
                                .scaledToFit()
                                .frame(maxWidth: UIScreen.main.bounds.width)
                        }
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 300)
                    .overlay(Text("写真").foregroundColor(.white))
                    .padding()
            }

            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        toggleGood(for: post, postUser: postUser)
                    }) {
                        if post.likedBy.contains(currentUser.id) {
                            Image("clap_fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                        } else {
                            Image("clap")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                    }
                    Text("\(post.goodCount)")
                        .font(.subheadline)
                    // Button(action: {
                    //     // コメントボタンのアクション
                    // }) {
                    //     Image("comment")
                    //         .resizable()
                    //         .frame(width: 24, height: 24)
                    // }
                    Spacer()
                }
                if !post.text.isEmpty {
                    Text(post.text)
                }

                // Text("コメントを見る")
                //     .font(.subheadline)
                //     .foregroundColor(.gray)

                Text("\(post.date.formatted())")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        // .id(post.id)
    }

    private func toggleGood(for post: Post, postUser: User) {
        if let postIndex = users.firstIndex(where: { $0.id == postUser.id }),
           let postInUserIndex = users[postIndex].posts.firstIndex(where: { $0.id == post.id }) {
            if users[postIndex].posts[postInUserIndex].likedBy.contains(currentUser.id) {
                users[postIndex].posts[postInUserIndex].goodCount -= 1
                users[postIndex].posts[postInUserIndex].likedBy.removeAll { $0 == currentUser.id }
            } else {
                users[postIndex].posts[postInUserIndex].goodCount += 1
                users[postIndex].posts[postInUserIndex].likedBy.append(currentUser.id)
            }
            FirestoreHelper.shared.saveUser(users[postIndex]) { result in
                switch result {
                case .success:
                    print("User data updated successfully")
                case .failure(let error):
                    print("Failed to update user data: \(error)")
                }
            }
        }
    }

    private func navigationBar() -> some View {
        HStack {
            Spacer()
            Button(action: {
                // ホーム画面に遷移するアクション
            }) {
                Image(systemName: "house")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            Spacer()
            Button(action: {
                isSearchViewActive = true
            }) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            .navigationDestination(isPresented: $isSearchViewActive) {
                SearchView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
            Spacer()
            NavigationLink(destination: CreatePostView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            ) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            Spacer()
            Button(action: {
                isUserProfileViewActive = true
            }) {
                Image(systemName: "person")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
            Spacer()
        }
        .foregroundColor(.white)
        .background(Color.black)
    }

    private func loadUsers() {
        let userIds = currentUser.following
        
        guard !userIds.isEmpty else {
            print("Following list is empty")
            return
        }

        FirestoreHelper.shared.loadUsers(userIds: userIds) { result in
            switch result {
            case .success(let loadedUsers):
                self.users = loadedUsers

            case .failure(let error):
                print("Error loading users: \(error)")
            }
        }
    }
    private func loadCurrentUser() {
    FirestoreHelper.shared.loadUser(userId: currentUser.id) { result in
        switch result {
        case .success(let loadedUser):
            DispatchQueue.main.async {
                self.currentUser = loadedUser
                self.isLoading = false
                print("User loaded: \(loadedUser.unreadMessagesCount())")
            }
        case .failure(let error):
            print("Error loading user: \(error)")
        }
    }
}
}
