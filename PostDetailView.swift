import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct PostDetailView: View {
    @Binding var user: User
    @Binding var currentUser: User
    @State var goodcount: Int?
    @Environment(\.dismiss) var dismiss
    @Binding var posts: [Post] // すべての投稿を受け取る
    @Binding var selectedPost: Post?
    @State private var showAlert = false
    @State private var postToDelete: Post?
    private var db = Firestore.firestore()
    @State private var isUserProfileViewActive = false
    @State private var isAnotherUserProfileViewActive = false
    @State private var maxHeight: CGFloat = 300 // デフォルトの高さ

    init(user: Binding<User>, currentUser: Binding<User>, posts: Binding<[Post]>, selectedPost: Binding<Post?>) {
        self._user = user
        self._currentUser = currentUser
        self._posts = posts
        self._selectedPost = selectedPost
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(posts.reversed()) { post in
                        PostRow(post: post, user: $user, currentUser: $currentUser)
                    }
                }
            }
            .onAppear {
                loadPosts(user: user)
                if let selectedPost = selectedPost {
                    proxy.scrollTo(selectedPost.id, anchor: .top) // 選択された投稿にスクロール
                }
            }
        }
        .navigationTitle("投稿")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
                if user.id == currentUser.id {
                    isUserProfileViewActive = true
                } else {
                    isAnotherUserProfileViewActive = true
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            }
        )
        .navigationDestination(isPresented: $isUserProfileViewActive) {
            UserProfileView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
            AnotherUserProfileView(user: $user, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
        }
        
    }

    private func toggleGood(for post: Post) {
        if let index = user.posts.firstIndex(where: { $0.id == post.id }) {
            if user.posts[index].likedBy.contains(currentUser.id) {
                // 既に「いいね」している場合
                user.posts[index].likedBy.removeAll { $0 == currentUser.id }
                user.posts[index].goodCount -= 1
                print("goodCount: \(user.posts[index].goodCount)")
            } else {
                // まだ「いいね」していない場合
                user.posts[index].likedBy.append(currentUser.id)
                user.posts[index].goodCount += 1
                print("goodCount: \(user.posts[index].goodCount)")
            }
            FirestoreHelper.shared.saveUser(user) { result in
                switch result {
                case .success:
                    print("User successfully saved!")
                case .failure(let error):
                    print("Error saving user: \(error)")
                }
            }

        }
    }

    private func createNotification(receiver: User, sender: User) {
        FirestoreHelper.shared.checkAndSaveNotificationgood(receiver: receiver, sender: sender) { result in
            switch result {
            case .success:
                print("Notification successfully saved!")
            case .failure(let error):
                print("Failed to save notification: \(error)")
            }
        }
    }

    

    private func loadPosts(user: User) {
        db.collection("posts").whereField("userId", isEqualTo: user.id).order(by: "date", descending: false).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting posts: \(error)")
                return
            }
            if let querySnapshot = querySnapshot {
                self.posts = querySnapshot.documents.compactMap { document -> Post? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                        return try JSONDecoder().decode(Post.self, from: data)
                    } catch {
                        print("Error decoding post: \(error)")
                        return nil
                    }
                }
            }
        }
    }

    private func deletePostFromFirestore(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                db.collection("users").document(currentUser.id).collection("posts").document(post.id).delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
}

struct PostRow: View {
    @State var post: Post
    @Binding var user: User
    @Binding var currentUser: User
    @State private var iconImage: UIImage? = nil
    @State private var postToDelete: Post?
    @State private var maxHeight: CGFloat = 300 // デフォルトの高さ
    @State private var showAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                    WebImage(url: url)
                        .resizable()
                        .onSuccess { image, data, cacheType in
                            // 成功時の処理
                        }
                        .onFailure { error in
                            // 失敗時の処理
                            ProgressView()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 28, height: 28)
                }
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                if user.id == currentUser.id {
                    Button(action: {
                        postToDelete = post
                        showAlert = true
                    }) {
                        Image("trash")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(.top, 16)
            
            .padding(.horizontal, 16)

            if !post.imageUrls.isEmpty {
                TabView {
                    ForEach(post.imageUrls, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .onSuccess { image, data, cacheType in
                                // 成功時の処理
                                }
                                .onFailure { error in
                                // 失敗時の処理
                                ProgressView()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                                }
                                .scaledToFit()
                                .frame(maxWidth: UIScreen.main.bounds.width)
                                .background(GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            let height = geo.size.height
                                            if height > maxHeight {
                                                maxHeight = height
                                            }
                                        }
                                })
                        }
                    }
                }
                .frame(height: maxHeight)
                .tabViewStyle(PageTabViewStyle())
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 300)
                    .overlay(Text("写真").foregroundColor(.white))
                    .padding()
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: {
                        if post.likedBy.contains(currentUser.id) {
                            post.goodCount -= 1
                            post.likedBy.removeAll { $0 == currentUser.id }
                        } else {
                            post.goodCount += 1
                            post.likedBy.append(currentUser.id)
                        }
                        toggleGood(for: post)
                        if user.id != currentUser.id {
                            createNotification(receiver: user, sender: currentUser)
                        }
                    }) {
                        Image(post.likedBy.contains(currentUser.id) ? "clap_fill" : "clap")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text("\(post.goodCount)")
                        .font(.subheadline)
                    // Button(action: {
                    //     // コメントボタンのアクション
                    // }) {
                    //     Image("comment")
                    //         .resizable()
                    //         .frame(width: 20, height: 20)
                    // }
                    Spacer()
                }
                .padding(.bottom, 8)
                if post.text != "" {
                    Text(post.text)
                    .padding(.bottom, 8)
                    .font(.subheadline)
                }
                // Text("コメントを見る")
                //     .foregroundColor(.gray)
                //     .font(.subheadline)
                //     .padding(.top, 8)
                Text("\(post.date.formatted())") // ここは適切な日付フォーマットに変更してください
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("投稿を削除しますか？"),
                message: Text("この操作は取り消せません。"),
                primaryButton: .destructive(Text("削除")) {
                    deletePost(post: postToDelete!)
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .id(post.id) // 各投稿にIDを設定
    }
    private func toggleGood(for post: Post) {
        if let index = user.posts.firstIndex(where: { $0.id == post.id }) {
            if user.posts[index].likedBy.contains(currentUser.id) {
                // 既に「いいね」している場合
                user.posts[index].likedBy.removeAll { $0 == currentUser.id }
                user.posts[index].goodCount -= 1
                print("goodCount: \(user.posts[index].goodCount)")
            } else {
                // まだ「いいね」していない場合
                user.posts[index].likedBy.append(currentUser.id)
                user.posts[index].goodCount += 1
                print("goodCount: \(user.posts[index].goodCount)")
            }
            FirestoreHelper.shared.saveUser(user) { result in
                switch result {
                case .success:
                    print("User successfully saved!")
                case .failure(let error):
                    print("Error saving user: \(error)")
                }
            }

        }
    }

    private func deletePost(post: Post) {
        user.posts.removeAll { $0.id == post.id }
        FirestoreHelper.shared.saveUser(user) { result in
            switch result {
            case .success:
                print("User successfully saved!")
            case .failure(let error):
                print("Error saving user: \(error)")
            }
        }
    }

    private func createNotification(receiver: User, sender: User) {
        FirestoreHelper.shared.checkAndSaveNotificationgood(receiver: receiver, sender: sender) { result in
            switch result {
            case .success:
                print("Notification successfully saved!")
            case .failure(let error):
                print("Failed to save notification: \(error)")
            }
        }
    }
}
