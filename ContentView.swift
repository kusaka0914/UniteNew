import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct ContentView: View {
    @State private var isLoggedIn: Bool = false
    @State private var isCheckingLoginState: Bool = true // ログイン状態確認中フラグ
    @State private var currentUser: User
    @State private var hasAgreedToTerms: Bool = UserDefaults.standard.bool(forKey: "hasAgreedToTerms") // 利用規約に同意したかどうかを管理
    let db = Firestore.firestore()
    let storage = Storage.storage()

    init(currentUser: User) {
        self._currentUser = State(initialValue: currentUser)
    }
    
    var body: some View {
        NavigationStack {
            if isCheckingLoginState {
                // ログイン状態確認中の待機ページ
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                    Image("Sphere")
                        .resizable()
                        .frame(width: 35, height: 35)
                    Text("Unite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    }
                    Spacer()
                }.background(Color.black)
                
            } else {
                if !hasAgreedToTerms {
                    RuleView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                        .transition(.opacity)
                } else if isLoggedIn {
                    UserProfileView(currentUser: $currentUser)
                        .transition(.opacity)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            checkLoginState()
            // addWebsiteFieldToAllUsers()
        }
    }

    private func addWebsiteFieldToAllUsers() {
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                print("エラーが発生しました: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("ドキュメントが存在しません。")
                return
            }

            for document in documents {
                let docRef = db.collection("users").document(document.documentID)
                docRef.updateData([
                    "website": "" // 空の配列を追加
                ]) { error in
                    if let error = error {
                        print("\(document.documentID) へのフィールド追加中にエラーが発生しました: \(error)")
                    } else {
                        print("\(document.documentID) に website フィールドが追加されました")
                    }
                }
            }
        }
    }

    func clearCollection() {
    let db = Firestore.firestore()
    let messagesRef = db.collection("users")
    
    messagesRef.getDocuments { (querySnapshot, error) in
        if let error = error {
            print("Error getting documents: \(error)")
            return
        }
        
        guard let documents = querySnapshot?.documents else {
            print("No documents found")
            return
        }
        
        for document in documents {
            document.reference.delete { error in
                if let error = error {
                    print("Error deleting document: \(error)")
                } else {
                    print("Document successfully deleted")
                }
            }
        }
    }
}


    func migrateAllUsersPostsImagesToImageUrls(completion: @escaping (Result<Void, Error>) -> Void) {
        let usersRef = db.collection("users")
        
        // 1. すべてのユーザードキュメントを取得
        usersRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.failure(NSError(domain: "No documents found", code: 404, userInfo: nil)))
                return
            }

            let dispatchGroup = DispatchGroup()

            for document in documents {
                let userId = document.documentID
                let postsRef = usersRef.document(userId).collection("posts")

                // 2. 各ユーザーのpostsコレクションのドキュメントを取得
                postsRef.getDocuments { (postSnapshot, error) in
                    if let error = error {
                        print("Error getting posts for user \(userId): \(error)")
                        dispatchGroup.leave()
                        return
                    }

                    guard let postDocuments = postSnapshot?.documents else { return }

                    for postDoc in postDocuments {
                        var postData = postDoc.data()
                        if var images = postData["images"] as? [Data] {  // `images`フィールドが存在する場合
                            var imageUrls: [String] = []
                            
                            // 3. 各画像をStorageにアップロードしURLを取得
                            for (index, imageData) in images.enumerated() {
                                let imageRef = self.storage.reference().child("posts_images/\(userId)_\(postDoc.documentID)_\(index).jpg")
                                
                                dispatchGroup.enter()
                                let metadata = StorageMetadata()
                                metadata.contentType = "image/jpeg"
                                
                                imageRef.putData(imageData, metadata: metadata) { metadata, error in
                                    if let error = error {
                                        print("Error uploading image for user \(userId), post \(postDoc.documentID): \(error)")
                                        dispatchGroup.leave()
                                        return
                                    }
                                    
                                    // URLを取得
                                    imageRef.downloadURL { url, error in
                                        if let error = error {
                                            print("Error getting download URL for user \(userId), post \(postDoc.documentID): \(error)")
                                        } else if let url = url {
                                            imageUrls.append(url.absoluteString)  // URLをリストに追加
                                        }
                                        dispatchGroup.leave()
                                    }
                                }
                            }

                            // 4. 画像URLへの変換完了後にFirestoreを更新
                            dispatchGroup.notify(queue: .main) {
                                postData["imageUrls"] = imageUrls  // 新しいimageUrlsフィールドを追加
                                postData.removeValue(forKey: "images")  // 古いimagesフィールドを削除

                                postsRef.document(postDoc.documentID).setData(postData) { error in
                                    if let error = error {
                                        print("Error updating Firestore for post \(postDoc.documentID): \(error)")
                                    } else {
                                        print("Successfully updated post \(postDoc.documentID) for user \(userId)")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // すべてのユーザーの処理が完了
            dispatchGroup.notify(queue: .main) {
                completion(.success(()))
            }
        }
    }


func addSolutionFieldToAllUsers() {
    let db = Firestore.firestore()

    // usersコレクションの全てのドキュメントを取得
    db.collection("users").getDocuments { (snapshot, error) in
        if let error = error {
            print("エラーが発生しました: \(error)")
            return
        }

        guard let documents = snapshot?.documents else {
            print("ドキュメントが存在しません。")
            return
        }

        // 各ドキュメントに solution フィールドを追加
        for document in documents {
            let docRef = db.collection("users").document(document.documentID)
            docRef.updateData([
                "solution": 0  // 必要に応じて値を設定
            ]) { error in
                if let error = error {
                    print("\(document.documentID) へのフィールド追加中にエラーが発生しました: \(error)")
                } else {
                    print("\(document.documentID) に solution フィールドが追加されました")
                }
            }
        }
    }
}


    private func checkLoginState() {
        if let userId = UserDefaults.standard.string(forKey: "loggedInUserId") {
            // Firestoreからユーザーデータを取得
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists {
                    do {
                        let userData = try JSONSerialization.data(withJSONObject: document.data()!, options: [])
                        let loadedUser = try JSONDecoder().decode(User.self, from: userData)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentUser = loadedUser
                            isLoggedIn = true
                        }
                    } catch {
                        print("ユーザーデータの読み込みに失敗しました。")
                    }
                }
                isCheckingLoginState = false
            }
        } else {
            isCheckingLoginState = false
        }
    }
}