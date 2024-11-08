import SwiftUI
import FirebaseFirestore
import PhotosUI
import FirebaseStorage
import SDWebImageSwiftUI

struct CreateGroupMessageView: View {
    @Binding var currentUser: User
    @State private var selectedUsers: Set<String> = []
    @State private var groupName: String = ""
    @State private var groupId: String = ""
    @State private var groupIconImageURL: String?
    @State private var selectedUsersId: [String] = []
    @State private var newGroupMessage: GroupMessage = GroupMessage(id: "", name: "", userIds: [], messages: [], iconImageURL: "")
    @State private var isGroupMessageViewActive = false
    @State private var users: [User] = []
    @State private var isAlertPresented = false
    @State private var alertMessage = ""
    @State private var isCreating = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @FocusState private var isGroupNameFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
        VStack {
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
                Text("グループメッセージ作成")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isCreating = true
                    if selectedUsers.count >= 2 && !groupName.isEmpty {
                        let userIds = Array(selectedUsers + [currentUser.id])
                        selectedUsersId = userIds
                        groupId = UUID().uuidString
                        newGroupMessage = GroupMessage(id: groupId, name: groupName, userIds: selectedUsersId, messages: [], iconImageURL: groupIconImageURL)
                        currentUser.groupMessages.append(newGroupMessage)
                        saveGroupMessageToFirestore(newGroupMessage)
                    } else {
                        alertMessage = "参加ユーザーを2名以上選択し、グループを入力してください"
                        isAlertPresented = true
                    }
                }) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text("作成")
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
                }.padding(.leading, 8)
                .padding(.trailing, 16)
            }.padding(.top, 16)

            // デフォルト画像または選択された画像を表示
            if let selectedImage = selectedImage, let groupIconImageURL = groupIconImageURL {
                WebImage(url: URL(string: groupIconImageURL))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle()) // 円形に切り取る
                    .aspectRatio(contentMode: .fill)
                    .padding()
            } else {
                Image("Sphere")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle()) // 円形に切り取る
                    .padding()
            }

            // アイコン画像選択
            PhotosPicker(selection: $selectedItem, matching: .images) {
    Text("写真フォルダーから選択")
        .foregroundColor(.blue)
        .padding(.bottom, 8)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        print("Image successfully loaded and set to selectedImage") // デバッグ出力
                        uploadIconImage(uiImage) { result in
                            switch result {
                            case .success(let url):
                                groupIconImageURL = url.absoluteString
                                print("Group Icon Image URL set: \(groupIconImageURL)") // デバッグ出力
                            case .failure(let error):
                                print("Failed to upload icon image: \(error)")
                            }
                        }
                    } else {
                        print("Failed to load image data")
                    }
                }
            }

            HStack {
            TextField("グループ名を入力", text: $groupName)
                .frame(width: 250,height: 40)
                .padding(.leading, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .focused($isGroupNameFocused)
            }.padding(.bottom, 16)
            if users.isEmpty {
                Text("ユーザーが見つかりません")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                HStack {
                Text("招待するユーザーを選択")
                    .font(.headline)
                    .padding(.leading, 32)
                    .padding(.bottom, 16)
                Spacer()
                }
                VStack {
                    ForEach(users, id: \.id) { user in
                        HStack {
                            Button(action: {
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedUsers.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.white)
                                        .padding(.leading, 16)
                                        .padding(.trailing, 8)
                                    if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                                        WebImage(url: url)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .padding(.trailing, 10)
                                    } else {
                                        Image("Sphere")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .padding(.trailing, 10)
                                    }
                                    VStack {
                                    HStack {
                                    Text(user.username)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    }
                                    HStack {
                                    Text(user.accountname)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 16)
            }
            Spacer()
        }.background(Color.black)
        .onAppear {
            loadUsers()
        }
        .alert(isPresented: $isAlertPresented) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                isCreating = false
            }))
        }
        .navigationDestination(isPresented: $isGroupMessageViewActive) {
            GroupMessageView(groupMessage: $newGroupMessage, currentUser: $currentUser, selectedUsersId: $selectedUsersId, iconImageURL: $groupIconImageURL, groupName: $groupName, selectedUser: currentUser, groupId: $groupId)
                .navigationBarBackButtonHidden(true)
        }
        .onTapGesture {
            isGroupNameFocused = false
        }
    }

    private func loadUsers() {
        let userIds = currentUser.following
        if userIds.count == 0 {
            print("No users to load")
            return
        }
        FirestoreHelper.shared.loadUsers(userIds: userIds) { result in
            switch result {
            case .success(let loadedUsers):
                self.users = loadedUsers
                print("Users loaded: \(self.users.count)")
            case .failure(let error):
                print("Error loading users: \(error)")
            }
        }
    }

    private func saveGroupMessageToFirestore(_ groupMessage: GroupMessage) {
        saveGroupMessageData(groupMessage)
    }

    private func saveGroupMessageData(_ groupMessage: GroupMessage) {
        do {
            let groupMessageData = try JSONEncoder().encode(groupMessage)
            let groupMessageDict = try JSONSerialization.jsonObject(with: groupMessageData) as! [String: Any]
            db.collection("groupMessages").document(groupMessage.id).setData(groupMessageDict) { error in
                if let error = error {
                    print("Error saving group message: \(error)")
                } else {
                    print("Group message successfully saved!")
                    updateUserGroupMessages(for: groupMessage)
                    FirestoreHelper.shared.saveUser(currentUser) { result in
                        switch result {
                        case .success:
                            print("Current user successfully saved!")
                            isGroupMessageViewActive = true
                            isCreating = false
                        case .failure(let error):
                            print("Error saving current user: \(error)")
                        }
                    }
                }
            }
        } catch {
            print("Error encoding group message: \(error)")
        }
    }

    private func updateUserGroupMessages(for groupMessage: GroupMessage) {
        let userIds = groupMessage.userIds
        
        for userId in userIds {
            let userRef = db.collection("users").document(userId)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if var user = try? document.data(as: User.self) {
                        if let index = user.groupMessages.firstIndex(where: { $0.id == groupMessage.id }) {
                            user.groupMessages[index] = groupMessage
                        } else {
                            user.groupMessages.append(groupMessage)
                        }
                        FirestoreHelper.shared.saveUser(user) { result in
                            switch result {
                            case .success:
                                print("User \(user.id) successfully updated!")
                            case .failure(let error):
                                print("Error updating user \(user.id): \(error)")
                            }
                        }
                    }
                } else {
                    print("User \(userId) does not exist")
                }
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
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                    self.groupIconImageURL = url.absoluteString
                    print("Group Icon Image URL set: \(self.groupIconImageURL)") // デバッグ出力
                }
            }
        }
    }
}