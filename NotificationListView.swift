import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct NotificationListView: View {
    @Binding var currentUserId: String
    @State var currentUser:User = User(id: "", password: "password", username: "currentUser", university: "University", posts: [], followers: [], following: [], accountname: "accountname", faculty: "faculty", department: "department", club: "club", bio: "bio", twitterHandle: "twitterHandle", email: "email", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [])
    @State var users: [User] = []
    @State var selectedUser: User
    @Environment(\.dismiss) var dismiss
    @State var isHomeViewActive: Bool = false
    @State var isAnotherUserProfileViewActive: Bool = false
    @State var isLoading: Bool = true
    private var db = Firestore.firestore()

    init(currentUserId: Binding<String>, selectedUser: User) {
        self._currentUserId = currentUserId
        self.selectedUser = selectedUser
    }

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView()
                    .onAppear {
                        loadCurrentUser() {
                            loadUsers()
                            markNotificationsAsRead(){                                
                                isLoading = false
                            }
                        }
                    }
            } else {
            ScrollView {
            VStack {
                if currentUser.notifications.isEmpty {
                    Text("通知がありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(currentUser.notifications.reversed(), id: \.id) { notification in
                        NotificationRow(notification: notification, currentUser: $currentUser, users: $users, selectedUser: $selectedUser, isAnotherUserProfileViewActive: $isAnotherUserProfileViewActive)
                    }
                }
                Spacer()
            }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                isHomeViewActive = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            }.navigationDestination(isPresented: $isHomeViewActive) {
                HomeView(currentUser: $currentUser, postUser: User(
                    id: "current_user_id",
                    password: "password",
                    username: "current_user",
                    university: "current_university",
                    posts: [],
                    followers: [],
                    following: [],
                    accountname: "current_accountname",
                    faculty: "current_faculty",
                    department: "current_department",
                    club: "current_club",
                    bio: "current_bio",
                    twitterHandle: "current_twitterHandle",
                    email: "current@example.com",
                    stories: [],
                    iconImageURL: "https://example.com/icon.jpg",
                    notifications: [],
                    messages: [],
                    courses: [],
                    groupMessages: []
                ))
                    .navigationBarBackButtonHidden(true)
            })
            .onAppear {
                loadCurrentUser() {
                    loadUsers()
                    markNotificationsAsRead(){
                        isLoading = false
                    }
                }
            }
            .background(
                NavigationLink(destination: AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                                .navigationBarBackButtonHidden(true),
                               isActive: $isAnotherUserProfileViewActive) {
                    EmptyView()
                }
            )
        }}
    }
    private func loadCurrentUser(completion: @escaping () -> Void) {
        FirestoreHelper.shared.loadUser(userId: currentUserId) { result in
            switch result {
            case .success(let user):
                currentUser = user
                completion()
            case .failure(let error):
                print("Error loading current user: \(error)")
            }
        }
    }

    private func loadUsers() {
        let senderIds = currentUser.notifications.map { $0.senderId }
        let uniqueSenderIds = Array(Set(senderIds))
        
        let dispatchGroup = DispatchGroup()
        
        for userId in uniqueSenderIds {
            dispatchGroup.enter()
            FirestoreHelper.shared.loadUser(userId: userId) { result in
                switch result {
                case .success(let user):
                    if !users.contains(where: { $0.id == user.id }) {
                        users.append(user)
                    }
                case .failure(let error):
                    print("Error loading user: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("All users loaded")
            
        }
    }

    private func markNotificationsAsRead(completion: @escaping () -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("No logged in user ID found")
            return
        }

        FirestoreHelper.shared.loadUser(userId: userId) { result in
            switch result {
            case .success(var user):
                for index in user.notifications.indices {
                    user.notifications[index].isRead = true
                }
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    switch saveResult {
                    case .success:
                        print("Notifications updated successfully")
                        completion()
                    case .failure(let error):
                        print("Failed to update notifications: \(error)")
                    }
                }
            case .failure(let error):
                print("User not found: \(error)")
            }
        }
    }
}

struct NotificationRow: View {
    var notification: Notification
    @Binding var currentUser: User
    @Binding var users: [User]
    @Binding var selectedUser: User
    @Binding var isAnotherUserProfileViewActive: Bool
    @State var unfollowbtnappear: Bool = false

    var body: some View {
        VStack {
        HStack{
        HStack {
            let iconImageURL = notification.senderIconURL
            if iconImageURL == "" {
                Image("Sphere")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .padding(.leading, 20)
            } else {
                WebImage(url: URL(string: iconImageURL))
                    .resizable()
                    .onFailure { error in
                        ProgressView()
                            .frame(width: 30, height: 30)
                            .padding(.leading, 20)
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .padding(.leading, 20)
            }
            Text(notification.message)
                .font(.subheadline)
            Spacer()
        }
        .frame(height: 40)
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // HStack全体をタップ可能にする
        .onTapGesture {
            if let userIndex = users.firstIndex(where: { $0.id == notification.senderId }) {
                selectedUser = users[userIndex]
                isAnotherUserProfileViewActive = true
            }
        }
        if notification.type == .follow {
                Button(action: {
                    if let userIndex = users.firstIndex(where: { $0.id == notification.senderId }) {
                        if currentUser.isFollowing(user: users[userIndex]) {
                            FirestoreHelper.shared.unfollowUser(follower: currentUser, followee: users[userIndex]) { result in
                                switch result {
                                case .success:
                                    DispatchQueue.main.async {
                                        currentUser.following.removeAll { $0 == users[userIndex].id }
                                        users[userIndex].followers.removeAll { $0 == currentUser.id }
                                    }
                                case .failure(let error):
                                    print("Failed to unfollow user: \(error)")
                                }
                            }
                        } else {
                            FirestoreHelper.shared.followUser(follower: currentUser, followee: users[userIndex]) { result in
                                switch result {
                                case .success:
                                    DispatchQueue.main.async {
                                        currentUser.following.append(users[userIndex].id)
                                        users[userIndex].followers.append(currentUser.id)
                                    }
                                case .failure(let error):
                                    print("Failed to follow user: \(error)")
                                }
                            }
                        }
                    }
                }) {
                    if let userIndex = users.firstIndex(where: { $0.id == notification.senderId }) {
                        Text(currentUser.isFollowing(user: users[userIndex]) ? "フォロー解除" : "フォロー")
                            .font(.subheadline)
                            .frame(width: 110, height: 35)
                            .background(currentUser.isFollowing(user: users[userIndex]) ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }.padding(.trailing, 16)
            }
        }
        }.background(Color.black)
    }
}