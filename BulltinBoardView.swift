import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct BulltinBoardView: View {
    @Binding var currentUser: User
    @State private var posts: [BulltinBoard] = []
    @State private var isBulltinBoardPostViewActive = false
    @State private var selectedPost: BulltinBoard? = nil
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
        VStack {
            HeaderView(currentUser: $currentUser)
            ScrollView {
                ForEach(posts) { post in
                    BulltinPostView(post: post, currentUser: $currentUser, selectedPost: $selectedPost)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
            }
            Spacer()
        }
        .onAppear {
            loadPosts()
            loadCurrentUser()
        }
        .background(Color(red: 18/255, green: 17/255, blue: 17/255))
    }

    private func loadPosts() {
        db.collection("bulletinBoardPosts").whereField("senderUniversity", isEqualTo: currentUser.university).getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.posts = documents.compactMap { queryDocumentSnapshot -> BulltinBoard? in
                let data = queryDocumentSnapshot.data()
                do {
                    var post = try JSONDecoder().decode(BulltinBoard.self, from: JSONSerialization.data(withJSONObject: data))
                    // UserDefaultsから解決済みの状態を読み込む
                    if !currentUser.blockedUsers.contains(post.userId) {
                        // UserDefaultsから解決済みの状態を読み込む
                        if let isResolved = UserDefaults.standard.value(forKey: "isResolved_\(post.id)") as? Bool {
                            post.isResolved = isResolved
                        }
                        return post
                    } else {
                        return nil
                    }
                } catch {
                    print("Failed to decode BulltinBoard: \(error)")
                    return nil
                }
            }
            // isResolvedがfalseの投稿を上に表示するためにソート
            self.posts.sort {
                if $0.userId == currentUser.id && $1.userId != currentUser.id {
                    return true
                } else if $0.userId != currentUser.id && $1.userId == currentUser.id {
                    return false
                } else if $0.isResolved == $1.isResolved {
                    return $0.date > $1.date
                }
                return !$0.isResolved && $1.isResolved
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

struct HeaderView: View {
    @Binding var currentUser: User
    @State private var isHomeViewActive = false
    @State private var isBulltinBoardPostViewActive = false
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
            Text("助け合い掲示板")
                .font(.headline)
            Spacer()
            Button(action: {
                    isBulltinBoardPostViewActive = true
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
                .navigationDestination(isPresented: $isBulltinBoardPostViewActive) {
                    BulltinBoardPostView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                .padding(.trailing, 16)
        }.padding(.leading, 16)
                    .padding(.top, 16)
    }
}

struct BulltinPostView: View {
    var post: BulltinBoard
    @Binding var currentUser: User
    @Binding var selectedPost: BulltinBoard?
    @State private var user: User? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
           
                Text(post.title)
                    .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                    .font(.title3)
                    .fontWeight(.bold)
            VStack(alignment: .leading, spacing: 16) {
            HStack {
            if post.isResolved {
                Text("解決済み")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green)
                    .cornerRadius(10)
            } else {
                Text("回答受付中")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            if post.userId == currentUser.id{
                Text("自分の投稿")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 45/255, green: 90/255, blue: 173/255))
                    .cornerRadius(10)
            }
            if let user = user {
            Text(user.department)
                .foregroundColor(.white)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                    .background(Color(red: 40/255, green: 38/255, blue: 158/255))
                    .cornerRadius(10)
            }
            }
            Text(relativeTimeString(from: post.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            HStack {
                if let user = user {
                    if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                        if iconImageURL == "" {
                            Image("Sphere")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
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
                                    
                        }
                    } else {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                            .font(.subheadline)
                        
                    }
                }
                Spacer()
                Text("詳細 >")
                    .foregroundColor(Color(red: 196/255, green: 192/255, blue: 192/255))
                    .font(.subheadline)
                    .padding(.trailing, 16)
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
        .background(
            NavigationLink(
                destination: BulltinBoardDetailView(post: post, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true),
                isActive: Binding(
                    get: { selectedPost == post },
                    set: { if !$0 { selectedPost = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .onAppear {
            loadUser()
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

    private func loadUser() {
        FirestoreHelper.shared.loadUser(userId: post.userId) { result in
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                print("Error loading user: \(error)")
            }
        }
    }
}