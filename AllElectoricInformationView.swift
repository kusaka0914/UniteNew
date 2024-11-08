import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct AllElectoricInformationView: View {
    @Binding var searchcondition: String
    @Binding var user: User
    @Binding var currentUser: User
    @State private var selectedUser: User
    @State private var users: [User] = []
    @State private var isUserProfileViewActive = false
    @Environment(\.dismiss) private var dismiss
    @State private var showFollowButton = true
    @State private var isLoading = false
    private var db = Firestore.firestore()


    init(searchcondition: Binding<String>, user: Binding<User>, currentUser: Binding<User>, selectedUser: User) {
        self._searchcondition = searchcondition
        self._user = user
        self._currentUser = currentUser
        self.selectedUser = selectedUser
    }

    var body: some View {
        // NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if users.isEmpty {
                            Spacer()
                            HStack {
                            Spacer()
                            Text("\(searchcondition)ユーザーがいません")
                                .foregroundColor(.gray)
                            Spacer()
                            }
                            Spacer()
                        } else {
                        ForEach($users) { $user in
                            UserRow(user: $user, currentUser: $currentUser, showFollowButton: $showFollowButton, onSelect: {
                                selectedUser = $user.wrappedValue
                                isUserProfileViewActive = true
                            })
                            
                        }
                        }
                    }
                }
            }
            }
            .onAppear {
                isLoading = true
                if searchcondition != "学内の全ユーザ" {
                loadUsers{
                searchcondition += "の"
                }
                }else if searchcondition == "学内の全ユーザ"{
                    searchcondition = "学内の"
                    loadAllUsers()
                }
            }
            .navigationTitle(
                "\(searchcondition)のユーザー"
            )
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .background(Color.black)
            .foregroundColor(.white)
            .navigationDestination(isPresented: $isUserProfileViewActive) {                
                    AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)   
            }
        // }
    }

    
    private func loadUsers(completion: @escaping () -> Void) {
    let university = currentUser.university
    
    db.collection("users").whereField("university", isEqualTo: university).whereField("faculty", isEqualTo: searchcondition).getDocuments { querySnapshot, error in
        if let error = error {
            print("Error getting documents for faculty: \(error)")
            return
        }
        if let documents = querySnapshot?.documents, !documents.isEmpty {
            let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                let data = queryDocumentSnapshot.data()
                return FirestoreHelper.shared.decodeUser(from: data)
            }
            self.users = allUsers.filter { $0.id != currentUser.id && !currentUser.blockedUsers.contains($0.id) } // currentUserを除外
            print("Users loaded from faculty: \(self.users)")
            isLoading = false
        } else {
            db.collection("users").whereField("university", isEqualTo: university).whereField("department", isEqualTo: searchcondition).getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents for department: \(error)")
                    return
                }
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                        let data = queryDocumentSnapshot.data()
                        return FirestoreHelper.shared.decodeUser(from: data)
                    }
                    self.users = allUsers.filter { $0.id != currentUser.id && !currentUser.blockedUsers.contains($0.id) } // currentUserを除外
                    print("Users loaded from department: \(self.users)")
                    isLoading = false
                } else {
                    db.collection("users").whereField("university", isEqualTo: university).whereField("courseNames", arrayContains: searchcondition).getDocuments { querySnapshot, error in
                        if let error = error {
                            print("Error getting documents for courseNames: \(error)")
                            return
                        }
                        if let documents = querySnapshot?.documents, !documents.isEmpty {
                            let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                                let data = queryDocumentSnapshot.data()
                                return FirestoreHelper.shared.decodeUser(from: data)
                            }
                            self.users = allUsers.filter { $0.id != currentUser.id && !currentUser.blockedUsers.contains($0.id) } // currentUserを除外
                            print("Users loaded from courseNames: \(self.users)")
                            isLoading = false
                        } else {
                            print("No documents found for courseNames")
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}

 
    private func loadAllUsers() {
        db.collection("users").whereField("university", isEqualTo: currentUser.university).getDocuments { querySnapshot, error in
            if let error = error {
                    print("Error getting documents for faculty: \(error)")
                    return
                }
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                        let data = queryDocumentSnapshot.data()
                        return FirestoreHelper.shared.decodeUser(from: data)
                    }
                    self.users = allUsers.filter { $0.id != currentUser.id && !currentUser.blockedUsers.contains($0.id) } // currentUserを除外
                    print("Users loaded from faculty: \(self.users)")
                    isLoading = false
                } else {
                    print("No documents found for faculty")
                    isLoading = false
                }
                
            }
        }
    private func loadCurrentUser() {
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("No logged in user ID found")
            return
        }

        FirestoreHelper.shared.loadUser(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedCurrentUser):
                    currentUser = savedCurrentUser
                case .failure(let error):
                print("Error loading current user: \(error)")
                currentUser = User(
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
                )
                }
            }
        }
    }
}

struct UserRow: View {
    @Binding var user: User
    @Binding var currentUser: User
    @Binding var showFollowButton: Bool
    @State private var unfollowbtnappear = false
    @State private var isUserProfileViewActive = false
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            onSelect()
        }) {
            HStack {
                if let iconImageURL = user.iconImageURL {
                    if iconImageURL == "" {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                    WebImage(url: URL(string: iconImageURL))
                                    .resizable()
                                    .onFailure { error in
                                        ProgressView()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                    }
                }
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                        .lineLimit(1)
                    Text(user.accountname)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
                Spacer()
                if showFollowButton {
                    Button(action: {
                        if unfollowbtnappear {
                            unfollowbtnappear = false
                            FirestoreHelper.shared.unfollowUser(follower: currentUser, followee: user) { result in
                                switch result {
                                case .success:
                                    DispatchQueue.main.async {
                                        currentUser.following.removeAll { $0 == user.id }
                                        user.followers.removeAll { $0 == currentUser.id }
                                    }
                                case .failure(let error):
                                    print("Failed to unfollow user: \(error)")
                                }
                            }
                        
                        } else {
                            unfollowbtnappear = true
                            FirestoreHelper.shared.followUser(follower: currentUser, followee: user) { result in
                                switch result {
                                case .success:
                                    DispatchQueue.main.async {
                                        currentUser.following.append(user.id)
                                        user.followers.append(currentUser.id)
                                    }
                                case .failure(let error):
                                    print("Failed to follow user: \(error)")
                                }
                            }
                        }
                    }) {
                        if currentUser.id != user.id {
                        Text(unfollowbtnappear ? "フォロー解除" : "フォロー")
                            .font(.subheadline)
                            .frame(width: 110, height: 35)
                            .background(unfollowbtnappear ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                        }
                    }
                }
            }.onAppear {
                unfollowbtnappear = currentUser.isFollowing(user: user)
            }
            .padding()
        }
    }
}