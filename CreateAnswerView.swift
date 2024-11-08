import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CreateAnswerView: View {
    @Binding var currentUser: User
    var post: BulltinBoard
    var receiverId: String // 投稿者のID
    @State private var text: String = ""
    @State private var images: [String] = []
    @State private var showImagePicker = false
    @State private var isPosting: Bool = false // 投稿中の状態を管理する変数
    @State private var showAlert: Bool = false // アラート表示用の状態変数
    @State private var alertMessage: String = "" // アラートメッセージ
    @FocusState private var isTextFieldFocused: Bool
    @State private var isBulltinBoardDetailViewActive: Bool = false
    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    init(currentUser: Binding<User>, post: BulltinBoard, receiverId: String) {
        self._currentUser = currentUser
        self.post = post
        self.receiverId = receiverId
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isBulltinBoardDetailViewActive = true
                }) {
                    if !isPosting {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding()
                    }
                }
                .navigationDestination(isPresented: $isBulltinBoardDetailViewActive) {
                    BulltinBoardDetailView(post: post, currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
                }
                Spacer()
                Text("回答")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if text.isEmpty {
                        alertMessage = "回答を入力してください。"
                        showAlert = true
                        return
                    }
                    isPosting = true // 投稿中の状態にする
                    let userId = currentUser.id
                    let userName = currentUser.username
                    let userIconUrl = currentUser.iconImageURL
                    let newAnswerId = UUID().uuidString
                    if !images.isEmpty {
                        uploadImages(images, answerId: newAnswerId) { result in
                            switch result {
                            case .success(let imageUrls):
                                let newAnswer = Answer(id: newAnswerId, postId: post.id, senderId: userId, receiverId: receiverId, text: text, images: imageUrls, senderName: userName, senderIconUrl: userIconUrl)
                                saveAnswerToFirestore(newAnswer)
                            case .failure(let error):
                                print("Error uploading images: \(error)")
                                isPosting = false // エラーが発生した場合は投稿中の状態を解除
                                alertMessage = "画像のアップロードに失敗しました"
                                showAlert = true
                            }
                        }
                    } else {
                        let newAnswer = Answer(id: newAnswerId, postId: post.id, senderId: userId, receiverId: receiverId, text: text, images: nil, senderName: userName, senderIconUrl: userIconUrl)
                        saveAnswerToFirestore(newAnswer)
                    }
                }) {
                    if isPosting {
                        ProgressView()
                            .padding()
                    } else {
                        Text("回答")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(isPosting) // 投稿中はボタンを無効にする
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            HStack {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(height: 150)
                        .padding(.top, 6)
                        .padding(.horizontal, 10)
                        .scrollContentBackground(.hidden)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .focused($isTextFieldFocused)
                    if text.isEmpty {
                        Text("回答を入力")
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 16)

            if !images.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(images, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight:300)
                                    .padding()
                            }
                        }
                    }
                }
            }

            Button(action: {
                showImagePicker = true
            }) {
                Text("画像を選択")
                    .foregroundColor(.blue)
            }
            .padding()

            Spacer()
        }
        .background(Color.black)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $images)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func uploadImages(_ images: [String], answerId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var imageUrls: [String] = []
        var uploadError: Error?

        for (index, imageUrl) in images.enumerated() {
            dispatchGroup.enter()
            let storageRef = storage.reference().child("answerImages/\(answerId)_\(index).jpg")
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

    private func saveAnswerToFirestore(_ answer: Answer) {
        do {
            let answerData = try JSONEncoder().encode(answer)
            let answerDict = try JSONSerialization.jsonObject(with: answerData, options: .allowFragments) as! [String: Any]
            db.collection("answers").document(answer.id).setData(answerDict) { error in
                if let error = error {
                    print("Error saving answer: \(error)")
                    isPosting = false // エラーが発生した場合は投稿中の状態を解除
                    alertMessage = "回答の保存に失敗しました"
                    showAlert = true
                } else {
                    print("Answer successfully saved!")
                    isPosting = false
                    isBulltinBoardDetailViewActive = true // 正常に保存された後にビューを遷移
                }
            }
        } catch {
            print("Error encoding answer: \(error)")
            isPosting = false // エラーが発生した場合は投稿中の状態を解除
            alertMessage = "回答のエンコードに失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}