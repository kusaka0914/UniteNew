import SwiftUI
import FirebaseFirestore
import PhotosUI
import SDWebImageSwiftUI
import FirebaseStorage

struct AllMemberView: View {
    @Binding var groupMessage: GroupMessage
    @Binding var groupName: String
    @Binding var currentUser: User
    @State private var isEditing = false // 編集モードを管理するState
    @State private var users: [User] = []
    @State private var images: [String] = []
    @State private var allUsersId: [String] = []
    @State private var selectedUser: User
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State private var showFollowButton = true
    @State private var isAddGroupUserViewActive = false
    @State private var isImagePickerActive = false
    @State private var selectedItem: PhotosPickerItem? // PhotosPickerで選択されたアイテム
    @State private var iconImage: UIImage? // 選択された画像を保持
    @State private var isSaving = false // 保存中の状態を管理する変数
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var iconImageURL: String?
    private var db = Firestore.firestore()
    private var storage = Storage.storage()


    init(groupMessage: Binding<GroupMessage>, groupName: Binding<String>, allUsersId: [String], currentUser: Binding<User>, selectedUser: User, iconImageURL: Binding<String?>) {
        self._groupMessage = groupMessage
        self._groupName = groupName
        self.allUsersId = allUsersId
        self._currentUser = currentUser
        self.selectedUser = selectedUser
        self._iconImageURL = iconImageURL
    }

    var body: some View {
        // NavigationStack {
            VStack {
                    VStack(spacing: 0) {
                        HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .imageScale(.large)
                                        .padding(.leading, 16)
                                }
                                Spacer()
                                Text("グループメッセージ")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    isSaving = true
                                    updateUsersGroupMessages()
                                }) {
                                    if isSaving {
                                        ProgressView()
                                    } else {
                                        if isEditing {
                                    Text("保存")
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
                                }.padding(.trailing, 16)
                            }.padding(.top, 16)
                            .padding(.bottom,32)
                            ScrollView {
                        if let iconImage = iconImage {
                            Image(uiImage: iconImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.bottom, 8)
                        } else if let iconImageURL = iconImageURL, let url = URL(string: iconImageURL) {
                            WebImage(url: url)
                                .resizable()
                                .onFailure { error in
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .padding(.trailing, 10)
                                        
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.bottom, 8)
                        } else {
                            Image("Sphere")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.bottom, 8)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                        if isEditing {
                            Text("写真フォルダーから選択")
                                .foregroundColor(.blue)
                                .padding(.bottom, 8)
                        }  
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                            let uiImage = UIImage(data: data) {
                                iconImage = uiImage
                                print("Image successfully loaded and set to iconImage") // デバッグ出力
                            } else {
                                print("Failed to load image data")
                            }
                        }
                    }
                        if isEditing {
                            TextField("グループ名を入力", text: $groupName)
                                .font(.headline)
                                .frame(width: 200, height: 40)
                                .padding(.leading, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                        } else {
                            Text(groupName)
                                .font(.headline)
                                .onTapGesture {
                                    isEditing = true // タップで編集モードに切り替え
                                }
                                .padding(.bottom, 8)
                                .padding(.top, 8)
                        }
                        if !isEditing {
                        Text("グループ名、アイコンを変更する")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                            .onTapGesture {
                                isEditing = true // タップで編集モードに切り替え
                            }
                        }
                        if !isEditing {
                        HStack {
                        Text("参加しているメンバー:\(users.count)人")
                            .font(.headline)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .padding(.top, 24)
                        VStack {
                        Image("adduser")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .padding(.leading, 16)
                            .padding(.top, 24)
                        Text("メンバー追加")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        }.onTapGesture {
                            isAddGroupUserViewActive = true
                        }
                        }.navigationDestination(isPresented: $isAddGroupUserViewActive) {
                            AddGroupUserView(currentUser: $currentUser, groupMessage: $groupMessage, allUsersId: $allUsersId)
                            .navigationBarBackButtonHidden(true)
                        }
                        if users.isEmpty {
                            
                            Spacer()
                            HStack {
                            Spacer()
                            Text("ユーザーがいません")
                                .foregroundColor(.gray)
                                
                            Spacer()
                            }
                            Spacer()
                        } else {
                        ForEach($users) { $user in
                            UserRow(user: $user, currentUser: $currentUser, showFollowButton: $showFollowButton, onSelect: {
                                selectedUser = $user.wrappedValue
                                if selectedUser.id != currentUser.id {
                                    isAnotherUserProfileViewActive = true
                                }else{
                                    isUserProfileViewActive = true
                                }
                            })
                            
                        }
                        }
                        }
                    }
                }
            }
            
            .onAppear {
                loadUsers()
                // loadCurrentUser(
            }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                    AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                    UserProfileView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
            }
        // }
    }
    
    private func loadUsers() {
       FirestoreHelper.shared.loadUsers(userIds: allUsersId) { result in
        switch result {
        case .success(let users):
            self.users = users
        case .failure(let error):
            print("Failed to load users: \(error)")
        }
       }
    }

    private func loadCurrentUser() {
        FirestoreHelper.shared.loadCurrentUser { result in
            switch result {
            case .success(let user):
                currentUser = user
            case .failure(let error):
                print("Current user not found: \(error)")
            }
        }
    }
    private func updateUsersGroupMessages() {
    guard let iconImage = iconImage else {
        saveGroupNameAndIcon()
        return
    }
    
    uploadIconImage(iconImage) { result in
        switch result {
        case .success(let url):
            DispatchQueue.main.async {
                print("url: \(url.absoluteString)")
                self.iconImageURL = url.absoluteString
                print("Icon Image URL set: \(self.iconImageURL)") // デバッグ出力
                self.saveGroupNameAndIcon()
            }
        case .failure(let error):
            print("Failed to upload icon image: \(error)")
            isSaving = false
        }
    }
}

private func uploadIconImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: nil)))
        return
    }
    
    let storageRef = storage.reference().child("groupIcons/\(UUID().uuidString).jpg")
    storageRef.putData(imageData, metadata: nil) { metadata, error in
        if let error = error {
            print("Upload error: \(error)")
            completion(.failure(error))
            return
        }
        
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Download URL error: \(error)")
                completion(.failure(error))
            } else if let url = url {
                print("Download URL: \(url)")
                completion(.success(url))
            }
        }
    }
}

private func saveGroupNameAndIcon() {
    for user in users {
        var updatedUser = user
        if let index = updatedUser.groupMessages.firstIndex(where: { $0.id == groupMessage.id }) {
            updatedUser.groupMessages[index].name = groupName
            updatedUser.groupMessages[index].iconImageURL = iconImageURL
        }
        FirestoreHelper.shared.saveUser(updatedUser) { result in
            switch result {
            case .success:
                print("User \(updatedUser.id) updated successfully")
                isSaving = false
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Failed to update user \(updatedUser.id): \(error)")
            }
        }
    }
}
}
