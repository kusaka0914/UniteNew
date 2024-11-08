import SwiftUI
import FirebaseFirestore
import UserNotifications
import SDWebImageSwiftUI

struct UserProfileView: View {
    @Binding var currentUser: User
    @State private var showBonusMessage = false
    @State private var isEditProfileViewActive = false
    @State private var isEditIconViewActive = false
    @State private var isSearchViewActive = false
    @State private var isAllFollowingViewActive = false
    @State private var isAllFollwedViewActive = false
    @State private var isHomeViewActive = false
    @State private var selectedPost: Post? = nil
    @State private var isPostDetailViewActive = false
    @State private var showLogoutAlert = false
    @State private var isLoginViewActive = false
    @State private var isCourseRegistrationViewActive = false
    @State private var isLoggedIn = true
    @State private var isMenuViewActive = false
    @State private var textToDelete: TextPost? = nil
    @State private var showDeleteAlert = false
    @State private var selectedTab: Tab = .posts
    @State private var showActionSheet = false
    private var db = Firestore.firestore()
    @State private var showAlertType1 = false
    @State private var showAlertType2 = false
    @State private var showAlertType3 = false
    @State private var selectedAlert: AlertType? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    enum AlertType {
        case type1
    }

    enum Tab {
        case posts, texts
    }

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
        // NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Text(currentUser.username)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.leading)
                            .foregroundColor(.white)
                        Spacer()
                        Text(currentUser.university)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                            .foregroundColor(.white)
                            .underline()
                        Button(action: {
                            isMenuViewActive = true
                        }) {
                            Image("menu")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }.padding(.trailing, 16)
                        .padding(.leading,8)
                        .navigationDestination(isPresented: $isMenuViewActive) {
                            MenuView(currentUser: $currentUser)
                                .navigationBarBackButtonHidden(true)
                        }
                    //     .actionSheet(isPresented: $showActionSheet) {
                    //     ActionSheet(
                    //         title: Text("メニュー"),
                    //         buttons: [
                    //             .destructive(Text("ログアウト")) {
                    //                 selectedAlert = .type2
                    //                 showAlertType2 = true
                    //             },
                    //             .destructive(Text("アカウント削除")) {
                    //                 selectedAlert = .type3
                    //                 showAlertType3 = true
                    //             },
                    //             .cancel()
                    //         ]
                    //     )
                    // }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    VStack {
                        HStack {
                            if let iconImageURL = currentUser.iconImageURL, let url = URL(string: iconImageURL) {
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
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                            VStack(alignment: .center) {
                                Text("解決数").font(.subheadline)
                                .foregroundColor(.white)
                                Text("\(currentUser.solution)")
                                .foregroundColor(.white)
                            }
                            VStack(alignment: .center) {
                                Text("フォロワー").font(.subheadline)
                                .foregroundColor(.white)
                                Text("\(currentUser.followers.count)")
                                .foregroundColor(.white)
                            }
                            .padding(.leading, 4)
                            .padding(.trailing, 4)
                            .onTapGesture {
                                isAllFollwedViewActive = true
                            }
                            .navigationDestination(isPresented: $isAllFollwedViewActive) {
                                AllFollwedView(user: $currentUser, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                                .navigationBarBackButtonHidden(true)
                            }
                            
                            VStack(alignment: .center) {
                                Text("フォロー中").font(.subheadline)
                                .foregroundColor(.white)
                                Text("\(currentUser.following.count)")
                                .foregroundColor(.white)
                            }
                            .onTapGesture {
                                isAllFollowingViewActive = true
                            }
                            .navigationDestination(isPresented: $isAllFollowingViewActive) {
                                AllFollowingView(user: $currentUser, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                                .navigationBarBackButtonHidden(true)
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
                        
                        if currentUser.accountname != "" {
                            HStack {
                                Text(currentUser.accountname)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                        } else {
                            HStack {
                                Text(currentUser.username)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                        }
                        
                        HStack {
                            Text(currentUser.faculty + " " + currentUser.department)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 2)
                        
                        HStack {
                            Text("所属サークル: " + currentUser.club)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 2)
                        
                        if currentUser.bio != "" {
                            HStack {
                                Text(currentUser.bio)
                                    .foregroundColor(.white)
                                + Text(" " + currentUser.twitterHandle)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .padding(.bottom,2)
                        }
                        if currentUser.website != "" {
                            let link = currentUser.website
                            if let url = URL(string: link) {
                            HStack {
                            Text(link)
                                .lineLimit(1)
                                .foregroundColor(Color.blue)
                                .onTapGesture {
                                    UIApplication.shared.open(url)
                                }
                                Spacer()
                            }.padding(.leading, 16)
                            .padding(.trailing, 60)
                            .padding(.bottom, 8)
                        }
                        }
                        
                        HStack {
                            Button(action: {
                                isEditProfileViewActive = true
                            }) {
                                Text("プロフィールを編集")
                                    .frame(width: 180, height: 35)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            }
                            .navigationDestination(isPresented: $isEditProfileViewActive) {
                                EditProfileView(currentUser: $currentUser, isEditProfileViewActive: $isEditProfileViewActive)
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
                                Text("履修科目を編集")
                                    .frame(width: 180, height: 35)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            }
                            .navigationDestination(isPresented: $isCourseRegistrationViewActive) {
                                CourseRegistrationView(user: $currentUser, currentUser: $currentUser)
                                    .navigationBarBackButtonHidden(true)
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
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
                        if currentUser.posts.count == 0 {
                            HStack {
                            Spacer()
                            Text("投稿がありません")
                                .foregroundColor(.gray)
                            Spacer()
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                                ForEach(currentUser.posts.reversed()) { post in
                                    PostThumbnailView(post: post)
                                        .onTapGesture {
                                            selectedPost = post
                                            print("post: \(post.id)")
                                            print("isPostDetailViewActive: \(isPostDetailViewActive)")
                                            isPostDetailViewActive = true
                                        }
                                }
                            }
                        }
                    } else if selectedTab == .texts {
                        if currentUser.texts.count == 0 {
                            HStack {
                            Spacer()
                            Text("テキストがありません")
                                .foregroundColor(.gray)
                                
                            Spacer()
                            }
                        } else {
                            ForEach(currentUser.texts.reversed()) { text in
                            ZStack(alignment: .topTrailing) {
                                HStack(alignment: .top) {
                                    if let iconImageURL = currentUser.iconImageURL, let url = URL(string: iconImageURL) {
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
                                            Text(currentUser.username)
                                                .font(.headline)
                                                .padding(.trailing, 8)
                                                .foregroundColor(.white)
                                             Text(relativeTimeString(from: text.date.dateValue()))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Button(action: {
                                        textToDelete = text
                                                selectedAlert = .type1
                                                showAlertType1 = true
                                            }) {
                                                Image("delete")      
                                                    .resizable()
                                                    .frame(width: 20, height: 20)
                                        }.padding(.trailing, 16)
                                        }
                                        Text(text.text)
                                            .font(.body)
                                            .padding(.bottom, 8)
                                            .foregroundColor(.white)
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
                            }
                        }
                    }
                }
                .padding(.leading, 16)
            }
            }.background(Color.black)
            
            
            HStack {
                Spacer()
                Button(action: {
                    isHomeViewActive = true
                }) {
                    Image(systemName: "house")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }
                .navigationDestination(isPresented: $isHomeViewActive) {
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
                Image(systemName: "person")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
                Spacer()
            }
            .foregroundColor(.white)
            .background(Color.black)
        // }
        .background(Color.black)
        .foregroundColor(.white)
        .onAppear {
            checkLogin()
            requestNotificationPermission()
        }
        // .alert(isPresented: $showBonusMessage) {
        //     Alert(
        //         title: Text("ボーナスメッセージ"),
        //         message: Text("今日は初めてログインしました！"),
        //         dismissButton: .default(Text("OK"), action: {
        //             showBonusMessage = false
        //         })
        //     )
        // }
        .alert(isPresented: Binding(
            get: {
                showAlertType1
            },
            set: { newValue in
                showAlertType1 = false
            }
        )) {
            switch selectedAlert {
            case .type1:
                return Alert(title: Text("テキストを削除しますか？"), message: Text(""), primaryButton: .destructive(Text("削除")) {
                    deleteText(textToDelete ?? TextPost(id: "", text: "", userId: "", goodCount: 0, likedBy: [], date: Timestamp(date: Date())))
                    showAlertType1 = false
                }, secondaryButton: .cancel(Text("キャンセル")) {
                    showAlertType1 = false
                })
            case .none:
                return Alert(title: Text("Unknown Alert"))
            }
        }
        .navigationDestination(isPresented: $isPostDetailViewActive) {
            if let selectedPost = selectedPost {
                PostDetailView(user: $currentUser, currentUser: $currentUser, posts: $currentUser.posts, selectedPost: $selectedPost)
                .navigationBarBackButtonHidden(true)
            }
        }
        .navigationDestination(isPresented: $isLoginViewActive) {
            LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
        }
    }

    // 通知の許可をリクエスト
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知の許可が得られました")
            } else {
                print("通知の許可が拒否されました")
            }
        }
    }
    
    // ローカル通知を送信する関数
    func sendNotification() {
        // 通知の内容を定義
        print("通知を送信しました")
        let content = UNMutableNotificationContent()
        content.title = "特典のお知らせ"
        content.body = "今日最初のログインで特典を受け取りました！"
        content.sound = .default
        
        // 通知のトリガーを設定（5秒後に発火）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知をスケジュールする際にエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }


    // ログイン日をチェックする関数
    // ログイン日をチェックする関数
func checkLogin() {
    let lastLoginDate = getLastLoginDate(for: currentUser.id)
    print("lastLoginDate: \(lastLoginDate)")
    let today = getCurrentDate()
    print("today: \(today)")
    
    if lastLoginDate == today {
        
    }else{
        showBonusMessage = true
        // currentUser.points += 5
        FirestoreHelper.shared.saveUser(currentUser) { result in
            switch result {
            case .success:
                print("User successfully saved!")
            case .failure(let error):
                print("Error saving user: \(error)")
            }
        }
        saveCurrentDate(for: currentUser.id) // 現在の日付を保存
    }
}

// 現在の日付を取得する
func getCurrentDate() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: Date()) // 今日の日付を文字列で返す
}

// 前回のログイン日を取得する
func getLastLoginDate(for userId: String) -> String? {
    return UserDefaults.standard.string(forKey: "LastLoginDate_\(userId)")
}

// 現在の日付を保存する
func saveCurrentDate(for userId: String) {
    let today = getCurrentDate()
    UserDefaults.standard.set(today, forKey: "LastLoginDate_\(userId)")
}


    private func toggleGood(for text: TextPost) {
    if let index = currentUser.texts.firstIndex(where: { $0.id == text.id }) {
        if currentUser.texts[index].likedBy.contains(currentUser.id) {
            currentUser.texts[index].likedBy.removeAll { $0 == currentUser.id }
            currentUser.texts[index].goodCount -= 1
        } else {
            currentUser.texts[index].likedBy.append(currentUser.id)
            currentUser.texts[index].goodCount += 1
        }
        FirestoreHelper.shared.saveUser(currentUser) { result in
            switch result {
            case .success:
                print("User successfully saved!")
            case .failure(let error):
                print("Error saving user: \(error)")
            }
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
    private func deleteText(_ text: TextPost) {
        if let index = currentUser.texts.firstIndex(where: { $0.id == text.id }) {
            currentUser.texts.remove(at: index)
            FirestoreHelper.shared.saveUser(currentUser) { result in
                switch result {
                case .success:
                    print("Text successfully deleted!")
                case .failure(let error):
                    print("Error deleting text: \(error)")
                }
            }
        }
    }
    
}

struct PostThumbnailView: View {
    var post: Post

    var body: some View {
        if let imageUrl = post.imageUrls.first, let url = URL(string: imageUrl) {
            WebImage(url: url)
                .resizable()
                .onFailure { error in
                    ProgressView()
                        .frame(width: 100, height: 100)
                }
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray)
                .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
                .cornerRadius(8)
        }
    }
}
