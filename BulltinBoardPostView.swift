import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct BulltinBoardPostView: View {
    @Binding var currentUser: User
    @State private var title: String = ""
    @State private var text: String = ""
    @State private var images: [String] = []
    @State private var showImagePicker = false
    @State private var isBulltinBoardViewActive: Bool = false
    @State private var isPosting: Bool = false // 投稿中の状態を管理する変数
    @State private var showAlert: Bool = false // アラート表示用の状態変数
    @State private var alertTitle: String = "" // アラートタイトル
    @State private var alertMessage: String = "" // アラートメッセージ
    @State private var alertType: AlertType = .error // アラートタイプ
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isTextFieldFocused2: Bool
    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    enum AlertType {
        case error
        case confirmation
    }

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isBulltinBoardViewActive = true
                }) {
                    if !isPosting {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                    }
                }.navigationDestination(isPresented: $isBulltinBoardViewActive) {
                    BulltinBoardView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                Spacer()
                Text("掲示板作成")
                    .font(.headline)
                Spacer()
                if !currentUser.isSubscribed {
                Button(action: {
                    // 投稿ボタンのアクション
                    if currentUser.points < 10 {
                        alertTitle = "エラー"
                        alertMessage = "ポイントが不足しています。投稿できません。"
                        alertType = .error
                        showAlert = true
                        return
                    }
                    if text.isEmpty || title.isEmpty {
                        alertTitle = "エラー"
                        alertMessage = "タイトルと概要を入力してください。"
                        alertType = .error
                        showAlert = true
                        return
                    }
                    
                    alertTitle = "確認"
                    alertMessage = "10P消費しますがよろしいですか？"
                    alertType = .confirmation
                    showAlert = true // 確認アラートを表示
                    
                }) {
                    if isPosting {
                        ProgressView()
                            .padding()
                    } else {
                        if !currentUser.isSubscribed {
                        if currentUser.points >= 10 {
                        Text("投稿")
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
                    }
                    }
                }
                .disabled(isPosting || currentUser.points < 10) // 投稿中またはポイントが不足している場合はボタンを無効にする
                }
                else{
                    Button(action: {
                        
                        if text.isEmpty || title.isEmpty {
                        alertTitle = "エラー"
                        alertMessage = "タイトルと概要を入力してください。"
                        alertType = .error
                        showAlert = true
                        return
                    }
                        alertTitle = "確認"
                        alertMessage = "この内容で投稿しますか？"
                        alertType = .confirmation
                        showAlert = true // 確認アラートを表示
                    
                    }) {
                        if isPosting {
                        ProgressView()
                            .padding()
                    } else {
                        Text("投稿")
                            .fontWeight(.bold)
                            .font(.subheadline)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }}
                    .disabled(isPosting)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            HStack {
                Spacer()
                VStack {
                    if !currentUser.isSubscribed {
                    Text("保有ポイント: \(currentUser.points)")
                        .foregroundColor(currentUser.points < 10 ? .red : .white)
                        .font(.subheadline)
                    if currentUser.points < 10 {
                        Text("ポイントが不足しています")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    }
                }
                Spacer()
            }
            .padding(.bottom, 16)
            HStack {
                TextField("タイトルを入力(必須)", text: $title)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .focused($isTextFieldFocused)
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
            }.padding(.horizontal, 12)
            .padding(.bottom, 20)
            HStack {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(height: 150)
                        .padding(.top,6)
                        .padding(.horizontal, 10)
                        .scrollContentBackground(.hidden)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .focused($isTextFieldFocused2)
                        .onTapGesture {
                            isTextFieldFocused2 = true
                        }
                    if text.isEmpty {
                        Text("概要を入力(必須)")
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                isTextFieldFocused2 = true
                            }
                    }
                }
            }.padding(.horizontal, 16)
            .padding(.bottom, 30)
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(images, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            Button(action: {
                showImagePicker = true
            }) {
                Text("画像を選択(任意)")
                    .foregroundColor(.blue)
                    
            }
            .padding()
            Spacer()
        }.background(Color.black)
        .onTapGesture {
            if isTextFieldFocused {
                isTextFieldFocused = false
            }
            if isTextFieldFocused2 {
                isTextFieldFocused2 = false
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $images)
        }
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .error:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            case .confirmation:
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("OK")) {
                        postBulltinBoard()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }

    private func postBulltinBoard() {
        isPosting = true // 投稿中の状態にする
        let userId = currentUser.id
        let newPostId = UUID().uuidString
        let senderUniversity = currentUser.university
        if !images.isEmpty {
            uploadImages(images, postId: newPostId) { result in
                switch result {
                case .success(let imageUrls):
                    let newPost = BulltinBoard(id: newPostId, title: title, text: text, images: imageUrls, userId: userId, senderUniversity: senderUniversity, responderId: nil)
                    savePostToFirestore(newPost)
                case .failure(let error):
                    print("Error uploading images: \(error)")
                    isPosting = false // エラーが発生した場合は投稿中の状態を解除
                }
            }
        } else {
            let newPost = BulltinBoard(id: newPostId, title: title, text: text, images: nil, userId: userId, senderUniversity: senderUniversity, responderId: nil)
            savePostToFirestore(newPost)
        }
    }

    private func uploadImages(_ images: [String], postId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var imageUrls: [String] = []
        var uploadError: Error?

        for (index, imageUrl) in images.enumerated() {
            dispatchGroup.enter()
            let storageRef = storage.reference().child("bulletinBoardImages/\(postId)_\(index).jpg")
            guard let imageData = try? Data(contentsOf: URL(string: imageUrl)!) else {
                uploadError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                dispatchGroup.leave()
                continue
            }

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    uploadError = error
                    dispatchGroup.leave()
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        uploadError = error
                        dispatchGroup.leave()
                        return
                    }

                    if let downloadURL = url?.absoluteString {
                        imageUrls.append(downloadURL)
                    } else {
                        uploadError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
            } else {
                completion(.success(imageUrls))
            }
        }
    }

    private func savePostToFirestore(_ post: BulltinBoard) {
        do {
            let postData = try JSONEncoder().encode(post)
            let postDict = try JSONSerialization.jsonObject(with: postData, options: .allowFragments) as! [String: Any]
            db.collection("bulletinBoardPosts").document(post.id).setData(postDict) { error in
                if let error = error {
                    print("Error saving post: \(error)")
                    isPosting = false // エラーが発生した場合は投稿中の状態を解除
                } else {
                    print("Post successfully saved!")
                    // データベースに正常に保存された後にビューを遷移
                    updateUserPoints()
                }
            }
        } catch {
            print("Error encoding post: \(error)")
            isPosting = false // エラーが発生した場合は投稿中の状態を解除
        }
    }

    private func updateUserPoints() {
        currentUser.points -= 10
        do {
            let userData = try JSONEncoder().encode(currentUser)
            let userDict = try JSONSerialization.jsonObject(with: userData, options: .allowFragments) as! [String: Any]
            db.collection("users").document(currentUser.id).setData(userDict) { error in
                if let error = error {
                    print("Error updating user points: \(error)")
                } else {
                    print("User points successfully updated!")
                    isPosting = false
                    isBulltinBoardViewActive = true
                }
            }
        } catch {
            print("Error encoding user: \(error)")
            isPosting = false // エラーが発生した場合は投稿中の状態を解除
        }
    }
}