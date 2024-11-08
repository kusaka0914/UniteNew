import SwiftUI
import Mantis
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import AVKit
import UniformTypeIdentifiers

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.showsPlaybackControls = true
        return controller
    }

    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        // 必要に応じて更新処理を追加
    }
}

struct CreatePostView: View {
    @Binding var currentUser: User
    @State var image: UIImage?
    @State var images: [UIImage] = []
    @State var isCropViewShowing = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect // トリミングの形を指定
    @State private var selectedItems: [String] = []
    @State private var showAlert = false
    @State private var isImagePickerPresented = false
    @State private var selectedVideoURL: URL?
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
    // NavigationStack {
        VStack {
            if let videoURL = selectedVideoURL, FileManager.default.fileExists(atPath: videoURL.path) {
    VideoPlayerView(videoURL: videoURL)
        .frame(height: 200)
        .cornerRadius(8)
        .onAppear {
            print("動画のプレビューが表示されます: \(videoURL)")
        }
} else {
    Text("動画ファイルが存在しません")
}
            Spacer()
            ScrollView(.horizontal) {
                HStack {
                    if images.count > 0 {
                        ForEach(images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                                .cornerRadius(8)
                        }.padding(.horizontal, 8)
                    }
                    // if let videoURL = selectedVideoURL {
                    //     VideoPlayer(player: AVPlayer(url: videoURL))
                    //         .frame(height: 200)
                    //         .cornerRadius(8)
                    //         .onAppear {
                    //             print("動画のプレビューが表示されます: \(videoURL)")
                    //         }
                    // }
                }
            }
            if images.count == 0 {
                Text("画像未選択の場合")
                    .padding(.top, 32)
                    .padding(.bottom, 4)
                Text("テキストとして投稿されます")
            }
            Spacer()
            if images.count == 1 {
                // HStack {
                //     Spacer()
                //     Button { // 四角トリミングボタン
                //         cropShapeType = .rect
                //         isCropViewShowing = true
                //     } label: {
                //         Image(systemName: "crop")
                //             .font(.title2)
                //     }
                //     .padding()
                //     Spacer()
                // }
                // Text("切り取れない場合はSquareを選択してください")
            }
            Button(action: {
            isImagePickerPresented = true
        }) {
            if selectedItems.count == 0 {
            Text("写真または動画を選択")
                .foregroundColor(.blue)
                .padding()
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImages: $selectedItems)
        }
            .onChange(of: selectedItems) { newItems in
    print("新しいアイテムが選択されました: \(newItems.count) 個")
    for newItem in newItems {
        if let url = URL(string: newItem) {
            print("URLが有効です: \(url)")
            if url.pathExtension == "jpg" {
                do {
                    let imageData = try Data(contentsOf: url)
                    if let uiImage = UIImage(data: imageData) {
                        images.append(uiImage)
                        print("画像が選択されました")
                    } else {
                        print("画像データの変換に失敗しました")
                    }
                } catch {
                    print("画像データの読み込みに失敗しました: \(error)")
                }
            } else if url.pathExtension == "mp4" {
                print("動画が選択されました: \(url)")
                selectedVideoURL = url
                print("選択された動画のURL: \(selectedVideoURL)")
            } else {
                print("不明なデータタイプ")
            }
        } else {
            print("URLの変換に失敗しました: \(newItem)")
        }
    }
}


        }.onChange(of: selectedVideoURL) { newURL in
            if let url = newURL {
                print("選択された動画のURL: \(url)")
                if FileManager.default.fileExists(atPath: url.path) {
                    print("ファイルが存在します: \(url.path)")
                } else {
                    print("ファイルが存在しません: \(url.path)")
                }
            }
        }
        
        .background(Color.black)
        .navigationBarTitle("画像選択", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            },
            trailing: NavigationLink(destination: NextView(currentUser: $currentUser, image: $image, images: $images)
                .navigationBarBackButtonHidden(true)
            ) {
                Text("次へ")
                    .foregroundColor(.white)
            }
        )
        // トリミング画面の表示
        .fullScreenCover(isPresented: $isCropViewShowing) {
            ImageCropper(image: $image, isCropViewShowing: $isCropViewShowing, cropShapeType: $cropShapeType)
                .ignoresSafeArea()
        }
    // }
}
private func uploadVideoToStorage(_ videoURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
    let videoId = UUID().uuidString
    let storageRef = Storage.storage().reference().child("videos/\(videoId).mp4")
    
    storageRef.putFile(from: videoURL, metadata: nil) { metadata, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        storageRef.downloadURL { url, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let downloadURL = url?.absoluteString {
                completion(.success(downloadURL))
            } else {
                completion(.failure(NSError(domain: "URLConversionError", code: -1, userInfo: nil)))
            }
        }
    }
}
}

struct NextView: View {
    @Binding var currentUser: User
    @Binding var image: UIImage?
    @Binding var images: [UIImage]
    @State private var postText: String = ""
    @State private var isUserProfileViewShowing = false
    @State private var showAlert = false
    @State private var showFirstPostAlert = false
    @FocusState private var isFocused: Bool
    @State private var isPosting = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, image: Binding<UIImage?>, images: Binding<[UIImage]>) {
        self._currentUser = currentUser
        self._image = image
        self._images = images
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
    HStack {
        if images.count > 0 {
        ForEach(images, id: \.self) { image in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .cornerRadius(8)
        }.padding(.horizontal, 8)
    }
    }.padding(.top, 16)
}
        if images.count == 0 {
        Text("テキストとして投稿されます")
        .padding(.top, 32)
        .padding(.bottom, 4)
}
            ZStack(alignment: .topLeading) {
                TextEditor(text: $postText)
                    .frame(height: 150) // 高さを設定
                    .padding(4)
                    .background(Color.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    ).focused($isFocused)
                if postText.isEmpty {
                    Text("テキストを入力")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .onTapGesture {
                            isFocused = true
                        }
                }
            }
            .padding()
            

            Button(action: {
                if images.count > 0 || !postText.isEmpty {
                    isPosting = true
                    saveContent()
                } else {
                    showAlert = true
                }
            }) {
                if isPosting {
                    ProgressView()
                } else {
                    Text("投稿する")
                        .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                }
            }.navigationDestination(isPresented: $isUserProfileViewShowing) {
                UserProfileView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text("画像かテキストを入力してください"), dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }.background(Color.black)
        
        .navigationBarTitle("新規投稿", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
    }

    private func uploadImageToStorage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: nil)))
        return
    }
    
    let imageId = UUID().uuidString
    let storageRef = Storage.storage().reference().child("images/\(imageId).jpg")
    
    storageRef.putData(imageData, metadata: nil) { metadata, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        storageRef.downloadURL { url, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let downloadURL = url?.absoluteString {
                completion(.success(downloadURL))
            } else {
                completion(.failure(NSError(domain: "URLConversionError", code: -1, userInfo: nil)))
            }
        }
    }
}

    private func saveContent() {
        if images.count > 0 {
            savePost()
        } else {
            saveText()
        }
    }

    private func savePost() {
    print("savePost")
    let dispatchGroup = DispatchGroup()
    var imageUrls: [String] = []
    var uploadError: Error?

    for image in images {
        dispatchGroup.enter()
        uploadImageToStorage(image) { result in
            switch result {
            case .success(let url):
                imageUrls.append(url)
            case .failure(let error):
                uploadError = error
            }
            dispatchGroup.leave()
        }
    }

    dispatchGroup.notify(queue: .main) {
        if let error = uploadError {
            print("Error uploading images: \(error)")
            return
        }

        let newPost = Post(id: UUID().uuidString, text: postText, userId: currentUser.id, imageUrls: imageUrls, goodCount: 0, likedBy: [], date: Date())
        currentUser.posts.append(newPost)

        savePostToFirestore(newPost) { result in
            switch result {
            case .success:
                FirestoreHelper.shared.saveUser(currentUser) { userSaveResult in
                    switch userSaveResult {
                    case .success:
                        print("User successfully saved!")
                        isUserProfileViewShowing = true
                    case .failure(let error):
                        print("Error saving user: \(error)")
                    }
                }
            case .failure(let error):
                print("Error saving post: \(error)")
            }
        }
    }
}


    private func saveText() {
        let newText = TextPost(id: UUID().uuidString, text: postText, userId: currentUser.id, date: Timestamp(date: Date()))
        currentUser.texts.append(newText)
        
        // Firestoreにテキストを保存
        saveTextToFirestore(newText) { result in
            switch result {
            case .success:
                // ユーザーを保存
                FirestoreHelper.shared.saveUser(currentUser) { userSaveResult in
                    switch userSaveResult {
                    case .success:
                        print("User successfully saved!")
                        isUserProfileViewShowing = true
                    case .failure(let error):
                        print("Error saving user: \(error)")
                    }
                }
                FirestoreHelper.shared.loadUser(userId: currentUser.id) { userSaveResult in
                    switch userSaveResult {
                    case .success:
                        print("User successfully loaded!")
                        // isUserProfileViewShowing = true
                    case .failure(let error):
                        print("Error loading user: \(error)")
                    }
                }
            case .failure(let error):
                print("Error saving text: \(error)")
            }
        }
    }

    private func savePostToFirestore(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            print("savePostToFirestore")
            let postData = try JSONEncoder().encode(post)
            let postDict = try JSONSerialization.jsonObject(with: postData) as! [String: Any]
            
            // Firestoreに保存する際、Date型をそのまま保存できるように修正
            let firestoreData = postDict.mapValues { value -> Any in
                if let date = value as? Date {
                    return Timestamp(date: date) // FirestoreのTimestamp型に変換
                }
                return value
            }
            
            db.collection("posts").document(post.id).setData(firestoreData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func checkFirstPostOfDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let userPostsRef = db.collection("users").document(currentUser.id).collection("posts").whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
        
        userPostsRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error checking first post of the day: \(error)")
                return
            }
            if let documents = querySnapshot?.documents, documents.count == 1 {
                // 初めての投稿
                print("初めての投稿です")
                showFirstPostAlert = true
                // currentUser.points += 5
                FirestoreHelper.shared.saveUser(currentUser) { result in
                    switch result {
                    case .success:
                        print("User successfully saved!")
                    case .failure(let error):
                        print("Error saving user: \(error)")
                    }
                }
            }else{
                print("初めての投稿ではありません")
            }
        }
    }

    private func saveTextToFirestore(_ text: TextPost, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let textData = try JSONEncoder().encode(text)
            let textDict = try JSONSerialization.jsonObject(with: textData) as! [String: Any]
            
            // Firestoreに保存する際、Date型をそのまま保存できるように修正
            let firestoreData = textDict.mapValues { value -> Any in
                if let date = value as? Date {
                    return Timestamp(date: date) // FirestoreのTimestamp型に変換
                }
                return value
            }
            
            db.collection("texts").document(text.id).setData(firestoreData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
