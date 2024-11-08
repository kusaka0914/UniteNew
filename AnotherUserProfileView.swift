import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct AnotherUserProfileView: View {
    @Binding var user: User
    @Binding var currentUser: User
    @State private var isEditProfileViewActive = false
    @State private var isAllElectoricInformationViewActive = false
    @State private var isSearchViewActive = false
    @State private var goodCount: Int?
    @Environment(\.dismiss) private var dismiss
    @State private var reloadTrigger = false
    @State private var iconImage: UIImage? = nil
    @State private var selectedPost: Post? = nil
    @State private var isPostDetailViewActive = false
    @State private var isMessageViewActive = false
    @State private var isCourseRegistrationViewActive = false
    @State private var selectedTab: Tab = .posts
    @State private var db = Firestore.firestore()
    @State private var unfollowbtnappear = false
    @State private var isAllFollwedViewActive = false
    @State private var isAllFollowingViewActive = false
    @State private var showReportAlert = false
    @State private var showBlockAlert = false
    @State private var showActionSheet = false
    @State private var selectedAlert: AlertType? = nil
    @State private var showAlert = false
    @State private var View: String = "AnotherUserProfileView"
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    enum Tab {
        case posts, texts
    }

    enum AlertType {
        case report
        case block
        case completionReport
        case completionBlock
    }

    init(user: Binding<User>, currentUser: Binding<User>) {
        self._user = user
        self._currentUser = currentUser
    }

    var body: some View {
        // NavigationStack {
            VStack {
                ScrollView {
                    VStack {
                        HStack {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding(.leading, 10)
                                .padding(.trailing,8)
                        }
                        
                        Text(user.username)
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            
                            Text(user.university)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.leading, 20)
                                .underline()
                                .padding(.trailing, 16)
                            Button(action: {
                            showActionSheet = true
                        }) {
                            Image("menu")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .padding(.trailing, 16)
                        .padding(.leading, 8)
                        .actionSheet(isPresented: $showActionSheet) {
                            ActionSheet(
                                title: Text("メニュー"),
                                buttons: [
                                    .destructive(Text("通報")) {
                                        selectedAlert = .report
                                        showAlert = true
                                    },
                                    .destructive(Text("ブロック")) {
                                        selectedAlert = .block
                                        showAlert = true
                                    },
                                    .cancel()
                                ]
                            )
                        }   
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                        
                        VStack {
                            HStack {
                                if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                        WebImage(url: url)
                                    .resizable()
                                    .onFailure { error in
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .padding(.trailing, 10)
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .padding(.trailing, 10)
                            } else {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(.trailing, 10)
                    }
                                VStack(alignment: .center) {
                                    Text("解決数").font(.subheadline)
                                    Text("\(user.solution)")
                                }
                                VStack(alignment: .center) {
                                    Text("フォロワー").font(.subheadline)
                                    Text("\(user.followers.count)")
                                }
                                .padding(.leading, 4)
                                .padding(.trailing, 4)
                                .onTapGesture {
                                    isAllFollwedViewActive = true
                                }
                                .navigationDestination(isPresented: $isAllFollwedViewActive) {
                                    AllFollwedView(user: $user, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                                    .navigationBarBackButtonHidden(true)
                                }
                                VStack(alignment: .center) {
                                    Text("フォロー中").font(.subheadline)
                                    Text("\(user.following.count)")
                                }
                                .onTapGesture {
                                    isAllFollowingViewActive = true
                                }
                                .navigationDestination(isPresented: $isAllFollowingViewActive) {
                                    AllFollowingView(user: $user, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                                    .navigationBarBackButtonHidden(true)
                                }
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            
                            if user.accountname != "" {
                                HStack {
                                    Text(user.accountname)
                                        .font(.body)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding(.leading, 16)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                            } else {
                                HStack {
                                    Text(user.username)
                                    Spacer()
                                }
                                .padding(.leading, 16)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                            }
                             
                            HStack {
                                Text(user.faculty + " " + user.department)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.bottom, 4)
                             
                            HStack {
                                Text("所属サークル: " + user.club)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.bottom, 16)
                             
                            if user.bio != "" {
                                HStack {
                                    Text(user.bio)
                                    + Text(" " + user.twitterHandle)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.leading, 16)
                                .padding(.bottom, 24)
                            }
                             
                            HStack {
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
                        Text(unfollowbtnappear ? "フォロー解除" : "フォロー")
                            .font(.subheadline)
                            .frame(width: 145, height: 35)
                            .background(unfollowbtnappear ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                                 
                                Button(action: {
                                    isMessageViewActive = true
                                }) {
                                    Text("メッセージ")
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 8)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                                .padding(.leading, 8)
                                .navigationDestination(isPresented: $isMessageViewActive) {
                                    MessageView(currentUser: $currentUser, otherUser: $user, prevView: $View)
                                        .navigationBarBackButtonHidden(true)
                                }
                                 
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.bottom,8)
                             
                            HStack {
                                Button(action: {
                                    isCourseRegistrationViewActive = true
                                }) {
                                    Text("履修科目を見る")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                                .navigationDestination(isPresented: $isCourseRegistrationViewActive) {
                                    CourseRegistrationView(user: $user, currentUser: $currentUser)
                                        .navigationBarBackButtonHidden(true)
                                }
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.bottom,24)

                            HStack {
                            Spacer()
                        Button(action: {
                            selectedTab = .posts
                        }) {
                            Text("投稿")
                                .padding(.horizontal, 50)
                                .padding(.vertical, 8)
                                .foregroundColor(selectedTab == .posts ? .black : .white)
                                .background(selectedTab == .posts ? Color.white : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                        }.padding(.trailing, 10)
                        Button(action: {
                            selectedTab = .texts
                        }) {
                            Text("テキスト")
                                .padding(.horizontal, 36)
                                .padding(.vertical, 8)
                                .foregroundColor(selectedTab == .texts ? .black : .white)
                                .background(selectedTab == .texts ? Color.white : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                
                        }
                        Spacer()
                    }
                    .padding(.bottom, 40)
                             
                            if selectedTab == .posts {
                                if user.posts.count == 0 {
                                    Text("投稿がありません")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 16)
                                .padding(.bottom, 24)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                                ForEach(user.posts.reversed()) { post in
                                    PostThumbnailView(post: post)
                                        .onTapGesture {
                                            selectedPost = post
                                            isPostDetailViewActive = true
                                        }
                                }
                            }
                        }
                    } else if selectedTab == .texts {
                        if user.texts.count == 0 {
                            Text("テキストがありません")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.bottom, 24)
                        } else {
                            ForEach(user.texts.reversed()) { text in
                                TextPostRow(text: text, currentUser: $currentUser, user: $user)
                            }
                        }
                    }
                        }
                        .padding(.leading, 16)
                    }
                }
                 
                Spacer()
                 
                HStack {
                    Spacer()
                    NavigationLink(destination: HomeView(currentUser: $currentUser, postUser: User(
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
                    .navigationBarBackButtonHidden(true)) {
                        Image(systemName: "house")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    Spacer()
                    NavigationLink(destination: SearchView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)) {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    Spacer()
                    NavigationLink(destination: CreatePostView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)) {
                        Image(systemName: "plus")
                            .resizable()
                        .frame(width: 24, height: 24)
                            .padding()
                    }
                    Spacer()
                    NavigationLink(destination: UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)) {
                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .background(Color.black)
            }
            .alert(isPresented: $showAlert) {
            switch selectedAlert {
            case .report:
                return Alert(
                    title: Text("ユーザーを通報しますか？"),
                    message: Text("このユーザーを通報してもよろしいですか？"),
                    primaryButton: .destructive(Text("通報")) {
                        reportUser()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            case .block:
                return Alert(
                    title: Text("ユーザーをブロックしますか？"),
                    message: Text("このユーザーをブロックしてもよろしいですか？"),
                    primaryButton: .destructive(Text("ブロック")) {
                        blockUser()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            case .completionReport:
                return Alert(title: Text("通報完了"), message: Text("ユーザーを正常に通報しました。"), dismissButton: .default(Text("OK")) {
                    selectedAlert = nil
                })
            case .completionBlock:
                return Alert(title: Text("ブロック完了"), message: Text("ユーザーを正常にブロックしました。"), dismissButton: .default(Text("OK")) {
                    selectedAlert = nil
                })
            case .none:
                return Alert(title: Text("エラー"), message: Text("不明なアクションです"), dismissButton: .default(Text("OK")))
            }
        }
            .background(Color.black)
            .foregroundColor(.white)
            .refreshable {
                reloadUserData()
            }
            .navigationDestination(isPresented: $isAllElectoricInformationViewActive) {
                // AllElectoricInformationView(user: $user, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                    // .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isPostDetailViewActive) {
                if let selectedPost = selectedPost {
                    PostDetailView(user: $user, currentUser: $currentUser, posts: $user.posts, selectedPost: $selectedPost)
                        .navigationBarBackButtonHidden(true)
                }
            }
        // }
        .id(reloadTrigger)
        .onAppear {
            if let iconImageURL = user.iconImageURL {
                loadImage(from: iconImageURL)
            }
            unfollowbtnappear = currentUser.isFollowing(user: user)
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

    private func reportUser() {
        let reportData: [String: Any] = [
            "reportedUserId": user.id,
            "reporterUserId": currentUser.id,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Failed to report user: \(error)")
            } else {
                print("User reported successfully")
                selectedAlert = .completionReport
                showAlert = true
            }
        }
    }
    
    private func blockUser() {
    let batch = db.batch()
    
    // ブロックリストにユーザーを追加
    let currentUserRef = db.collection("users").document(currentUser.id)
    batch.updateData(["blockedUsers": FieldValue.arrayUnion([user.id])], forDocument: currentUserRef)
    
    // followingからブロックしたユーザーを削除
    if let index = currentUser.following.firstIndex(of: user.id) {
        currentUser.following.remove(at: index)
        batch.updateData(["following": currentUser.following], forDocument: currentUserRef)
    }
    
    // バッチをコミット
    batch.commit { error in
        if let error = error {
            print("Failed to block user: \(error)")
        } else {
            print("User blocked and removed from following list successfully")
            selectedAlert = .completionBlock
            showAlert = true
        }
    }
}

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.iconImage = uiImage
                }
            }
        }
        task.resume()
    }
     
    private func reloadUserData() {
        FirestoreHelper.shared.loadUser(userId: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedUser):
                    self.user = updatedUser
                case .failure(let error):
                    print("Error reloading user data: \(error)")
                }
            }
        }
    }
     
    private func followUser() {
        FirestoreHelper.shared.followUser(follower: currentUser, followee: user) { result in
            switch result {
            case .success:
                reloadUserData()
                reloadTrigger.toggle()
            case .failure(let error):
                print("Error following user: \(error)")
            }
        }
    }
     
    private func unfollowUser() {
        FirestoreHelper.shared.unfollowUser(follower: currentUser, followee: user) { result in
            switch result {
            case .success:
                reloadUserData()
                reloadTrigger.toggle()
            case .failure(let error):
                print("Error unfollowing user: \(error)")
            }
        }
    }
    private func toggleGood(for text: TextPost) {
    if let index = user.texts.firstIndex(where: { $0.id == text.id }) {
        print("index: \(index)")
        if user.texts[index].likedBy.contains(currentUser.id) {
            user.texts[index].goodCount -= 1
            user.texts[index].likedBy.removeAll { $0 == currentUser.id }
            
        } else {
            user.texts[index].goodCount += 1
            user.texts[index].likedBy.append(currentUser.id)
        }
        FirestoreHelper.shared.saveUser(user) { result in
            switch result {
            case .success:
                print("Success to update user data")
            case .failure(let error):
                print("Failed to update user data: \(error)")
            }
        }
    }
}
private func createNotification() {
        FirestoreHelper.shared.checkAndSaveNotificationgood(receiver: user, sender: currentUser) { result in
            switch result {
            case .success:
                print("Notification saved successfully")
            case .failure(let error):
                print("Failed to save notification: \(error)")
            }
        }
    }

}

struct TextPostRow: View {

    @State var text: TextPost
    @Binding var currentUser: User
    @Binding var user: User
    @State private var iconImage: UIImage? = nil

    var body: some View {
    HStack(alignment: .top) {
                                    if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                                        WebImage(url: url)
                                    .resizable()
                                    .onFailure { error in
                                        ProgressView()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .padding(.trailing, 8)
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                                    
                                    } else {
                                        Image("Sphere")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .padding(.trailing, 8)
                                            
                                    }
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack {
                                            Text(user.username)
                                                .font(.headline)
                                                .padding(.trailing, 8)
                                             Text(relativeTimeString(from: text.date.dateValue()))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            
                                        }
                                        Text(text.text)
                                            .font(.body)
                                            .padding(.vertical, 8)
                                        HStack {
                                            Button(action: {
                                                toggleGood(for: text)
                                                
                                            }) {
                                                Image(text.likedBy.contains(currentUser.id) ? "clap_fill" : "clap")
                                                    .resizable()
                                                    .frame(width: 20, height: 20)
                                            }
                                            Text("\(text.goodCount)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.leading, 16)
                                .padding(.bottom, 20)
    }

    private func toggleGood(for text: TextPost) {
    if let index = user.texts.firstIndex(where: { $0.id == text.id }) {
        print("index: \(index)")
        if user.texts[index].likedBy.contains(currentUser.id) {
            user.texts[index].goodCount -= 1
            user.texts[index].likedBy.removeAll { $0 == currentUser.id }
            
        } else {
            user.texts[index].goodCount += 1
            user.texts[index].likedBy.append(currentUser.id)
        }
        FirestoreHelper.shared.saveUser(user) { result in
            switch result {
            case .success:
                print("Success to update user data")
            case .failure(let error):
                print("Failed to update user data: \(error)")
            }
        }
    }
}
private func createNotification() {
        FirestoreHelper.shared.checkAndSaveNotificationgood(receiver: user, sender: currentUser) { result in
            switch result {
            case .success:
                print("Notification saved successfully")
            case .failure(let error):
                print("Failed to save notification: \(error)")
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
}