import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct EverythingBoardView: View {
    @Binding var currentUser: User
    @State private var user: User
    @State private var posts: [EverythingBoard] = []
    @State private var users: [User] = []
    @State private var isCreateEverythingBoardViewActive = false
    @State private var selectedPost: EverythingBoard? = nil
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, user: User) {
        self._currentUser = currentUser
        self.user = user
    }

    var body: some View {
        VStack {
            EverythingBoardHeaderView(currentUser: $currentUser)
            ScrollView {
                ForEach(posts) { post in
                    EverythingBoardPostView(post: post, currentUser: $currentUser, selectedPost: $selectedPost, users: $users, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], everythingBoards: [], points: 0), user: user)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
            }
            Spacer()
            // NavigationLink(destination: CreateEverythingBoardView(currentUser: $currentUser)
            //     .navigationBarBackButtonHidden(true), isActive: $isCreateEverythingBoardViewActive) {
            //     Button(action: {
            //         isCreateEverythingBoardViewActive = true
            //     }) {
            //         Text("投稿を作成")
            //             .foregroundColor(.white)
            //             .fontWeight(.bold)
            //             .padding(.horizontal, 16)
            //             .padding(.vertical, 12)
            //             .background(Color.blue)
            //             .cornerRadius(10)
            //     }
            //     .padding(.top, 10)
            //     .padding(.bottom, 20)
            // }
        }
        .onAppear {
            loadPosts()
            loadUser()
            loadCurrentUser()
        }
        .background(Color(red: 18/255, green: 17/255, blue: 17/255))
    }

    func loadUser() {
        for post in posts {
            FirestoreHelper.shared.loadUser(userId: post.userId) { result in
                switch result {
                case .success(let user):
                    self.users.append(user)
                case .failure(let error):
                    print("Error loading user: \(error)")
                }
            }
        }
    }
    
    private func loadPosts() {
        db.collection("everythingBoardPosts")
            .whereField("senderUniversity", isEqualTo: currentUser.university)
            .order(by: "date", descending: true) // 日付で降順に並べ替え
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                self.posts = documents.compactMap { document in
                do {
                    let post = try document.data(as: EverythingBoard.self)
                    // ブロックしていないユーザーの投稿のみをフィルタリング
                    if !currentUser.blockedUsers.contains(post.userId) {
                        return post
                    } else {
                        return nil
                    }
                } catch {
                    print("Error decoding document: \(error.localizedDescription)")
                    return nil
                }
            }
                // 手動で並べ替え
                self.posts.sort {
                    if $0.userId == currentUser.id && $1.userId != currentUser.id {
                        return true
                    } else if $0.userId != currentUser.id && $1.userId == currentUser.id {
                        return false
                    } else {
                        return $0.date > $1.date
                    }
                }
            }
    }

    private func loadCurrentUser() {
        FirestoreHelper.shared.loadUser(userId: currentUser.id) { result in
            switch result {
            case .success(let user):
                self.currentUser = user
            case .failure(let error):
                print("Error loading user: \(error)")
            }
        }
    }
}

struct EverythingBoardHeaderView: View {
    @Binding var currentUser: User
    @State private var isHomeViewActive = false
    @State private var isCreateEverythingBoardViewActive = false
    var body: some View {
        HStack {
            Button(action: {
                isHomeViewActive = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    
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
            }
            Spacer()
            Text("なんでも掲示板")
                .font(.headline)
            Spacer()
            Button(action: {
                    isCreateEverythingBoardViewActive = true
                }) {
                    Text("+ 投稿作成")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                .navigationDestination(isPresented: $isCreateEverythingBoardViewActive) {
                    CreateEverythingBoardView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                .padding(.trailing, 16)
            
        }.padding(.leading, 16)
                    .padding(.top, 16)
    }
}

struct EverythingBoardPostView: View {
    @State var post: EverythingBoard
    @Binding var currentUser: User
    @Binding var selectedPost: EverythingBoard?
    @Binding var users: [User]
    @State var isMessageViewActive = false
    @State var isgood: Bool = true
    @State var selectedUser: User
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State private var prevView: String = "EverythingBoardView"
    @State var user: User
    @State var goodcount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                    if iconImageURL == "" {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .onTapGesture {
                                if user.id != currentUser.id {
                                    selectedUser = user
                                    isAnotherUserProfileViewActive = true
                                }else{
                                    isUserProfileViewActive = true
                                }
                            }
                    } else {
                        WebImage(url: url)
                            .resizable()
                            .onFailure { error in
                                ProgressView()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .padding(.trailing, 10)
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .onTapGesture {
                                if user.id != currentUser.id {
                                    selectedUser = user
                                    isAnotherUserProfileViewActive = true
                                }else{
                                    isUserProfileViewActive = true
                                }
                            }
                    }
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                selectedUser = user
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                }
                VStack(alignment: .leading) {
                    Text(user.username)
                        .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                        .font(.subheadline)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                selectedUser = user
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                }
                Button(action: {
                    isMessageViewActive = true
                }) {
                    if post.userId != currentUser.id {
                    Text("メッセージへ")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                }.padding(.leading, 8)
                .navigationDestination(isPresented: $isMessageViewActive) {
                    MessageView(currentUser: $currentUser, otherUser: $user, prevView: $prevView)
                        .navigationBarBackButtonHidden(true)
                }
            
                Spacer()
            }.navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
            Text(post.title)
                .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                .font(.title3)
                .fontWeight(.bold)
            Text(post.text)
                .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                .font(.body)
            if let link = post.link, let url = URL(string: link) {
            Text(link)
                .foregroundColor(Color.blue)
                .font(.caption)
                .onTapGesture {
                    UIApplication.shared.open(url)
                }
        }
            if let imageUrls = post.images {
                TabView {
                    ForEach(imageUrls, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: UIScreen.main.bounds.width - 40)
                                    .padding(.horizontal, 16)
                                    // .padding(.bottom, 16)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
                .frame(height: 300) // 画像の高さを設定
                .tabViewStyle(PageTabViewStyle())
            }
            HStack {
                Text(post.category)
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(10)
                if post.userId == currentUser.id {
                    Text("自分の投稿")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 45/255, green: 90/255, blue: 173/255))
                        .cornerRadius(10)
                }
                    Text(user.department)
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 40/255, green: 38/255, blue: 158/255))
                        .cornerRadius(10)
            }
            HStack {
                Text(relativeTimeString(from: post.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                Button(action: {
                    if isgood {
                        isgood = false
                        goodcount -= 1
                        toggleGood(for: post)
                    } else {
                        isgood = true
                        goodcount += 1
                        toggleGood(for: post)
                    }
                }) {
                    
                        Image(isgood ? "star_fill" : "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("\(goodcount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    
                }
                }
        }
        .padding()
        .background(Color(red: 33/255, green: 33/255, blue: 33/255))
        .onTapGesture {
            selectedPost = post
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 0.5)
        )
        .onAppear {
            loadUser{
                if let postInEverythingBoards = user.everythingBoards.first(where: { $0.id == post.id }) {
                print("Post found in everythingBoards: \(postInEverythingBoards)")
                    if postInEverythingBoards.likedBy.contains(currentUser.id) {
                        isgood = true
                        goodcount = postInEverythingBoards.goodCount
                        print("Current user has liked the post")
                    } else {
                        isgood = false
                        goodcount = postInEverythingBoards.goodCount
                        print("Current user has not liked the post")
                    }
                } else {
                    isgood = false
                    print("Post not found in everythingBoards")
                }
                print("isgood: \(isgood)")
            }
        }
    }
    
    func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)

        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)ヶ月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)週間前"
        } else if let day = components.day, day > 0 {
            return "\(day)日前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)時間前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分前"
        } else if let second = components.second, second > 0 {
            return "\(second)秒前"
        } else {
            return "たった今"
        }
    }

    private func loadUser(completion: @escaping () -> Void) {
        if let user = users.first(where: { $0.id == post.userId }) {
            self.user = user
        } else {
            FirestoreHelper.shared.loadUser(userId: post.userId) { result in
                switch result {
                case .success(let user):
                    self.user = user
                    print("1")
                    if !users.contains(where: { $0.id == user.id }) {
                        self.users.append(user)
                    }
                case .failure(let error):
                    print("Error loading user: \(error)")
                }
                completion()
            }
        }
    }

    private func toggleGood(for post: EverythingBoard) {
        guard let userIndex = users.firstIndex(where: { $0.id == post.userId }) else { return }
        guard let postIndex = users[userIndex].everythingBoards.firstIndex(where: { $0.id == post.id }) else { return }

        if users[userIndex].everythingBoards[postIndex].likedBy.contains(currentUser.id) {
            users[userIndex].everythingBoards[postIndex].goodCount -= 1
            users[userIndex].everythingBoards[postIndex].likedBy.removeAll { $0 == currentUser.id }
        } else {
            users[userIndex].everythingBoards[postIndex].goodCount += 1
            users[userIndex].everythingBoards[postIndex].likedBy.append(currentUser.id)
        }

        // 更新されたユーザー情報を user に反映
        self.user = users[userIndex]
        self.post = users[userIndex].everythingBoards[postIndex]

        FirestoreHelper.shared.saveUser(users[userIndex]) { result in
            switch result {
            case .success:
                print("Success to update user data")
            case .failure(let error):
                print("Failed to update user data: \(error)")
            }
        }
    }
}