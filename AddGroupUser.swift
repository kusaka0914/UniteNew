import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct AddGroupUserView: View {
    @Binding var currentUser: User
    @Binding var groupMessage: GroupMessage
    @State private var users: [User] = []
    @State private var selectedUsers: Set<String> = []
    @State private var selectedUsersId: [String] = []
    @State private var isAdding: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Binding var allUsersId: [String]
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, groupMessage: Binding<GroupMessage>, allUsersId: Binding<[String]>) {
        self._currentUser = currentUser
        self._groupMessage = groupMessage
        self._allUsersId = allUsersId
    }

    var body: some View {
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
                                Text("メンバー追加")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    isAdding = true
                                    if selectedUsers.isEmpty {
                                        isAdding = false
                                        showAlert = true
                                        alertMessage = "ユーザーを選択してください"
                                    } else {
                                        let userIds = Array(selectedUsers)
                                        selectedUsersId = userIds
                                        createGroupMessageForSelectedUsers()
                                        addSelectedUsersToGroup()
                                        allUsersId.append(contentsOf: selectedUsersId)
                                    }
                                }) {
                                    if isAdding {
                                        ProgressView()
                                    } else {
                                        Text("追加")
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
                                }.padding(.trailing, 16)
                            }.padding(.top, 16)
                    ScrollView {
                    if users.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("招待できるユーザーがいません")
                                .foregroundColor(.gray)
                                .padding(.bottom,16)
                            Spacer()
                        }
                        Spacer()
                    } else {
                        Text("招待したいユーザーを選択")
                                    .font(.headline)
                                    .padding(.bottom,16)
                                    .padding(.top,24)
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
                                        VStack(alignment: .leading) {
                                            Text(user.username)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text(user.accountname)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }.padding(.vertical,8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFollowingUsers()
        }
        .background(Color.black)
        .foregroundColor(.white)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func loadFollowingUsers() {
        if currentUser.following.isEmpty {
            users = []
        } else {
        let followingIds = currentUser.following
        FirestoreHelper.shared.loadUsers(userIds: followingIds) { result in
            switch result {
            case .success(let users):
                // フォローしているが、groupMessage.userIdsに含まれていないユーザーをフィルタリング
                self.users = users.filter { !groupMessage.userIds.contains($0.id) }
            case .failure(let error):
                print("Failed to load following users: \(error)")
            }
        }
    }
}

    private func createGroupMessageForSelectedUsers() {
    let dispatchGroup = DispatchGroup()
    let allIds = groupMessage.userIds + selectedUsersId
    
    for userId in allIds {
        dispatchGroup.enter()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, var userData = document.data(), var groupMessages = userData["groupMessages"] as? [[String: Any]] {
                // 新しいグループメッセージを追加
                let newGroupMessage = ["iconImageURL": groupMessage.iconImageURL, "id": groupMessage.id, "messages": groupMessage.messages, "name": groupMessage.name, "userIds": allIds]
                groupMessages.append(newGroupMessage)
                userData["groupMessages"] = groupMessages
                
                db.collection("users").document(userId).updateData(userData) { error in
                    if let error = error {
                        print("Failed to create group message for user \(userId): \(error.localizedDescription)")
                    } else {
                        print("Group message created successfully for user \(userId)")
                    }
                    dispatchGroup.leave()
                }
            } else {
                print("Failed to fetch user data for user \(userId): \(error?.localizedDescription ?? "Unknown error")")
                dispatchGroup.leave()
            }
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        print("All group messages created")
    }
}

        private func addSelectedUsersToGroup() {
    isAdding = true
    let allIds = groupMessage.userIds + selectedUsersId
    let dispatchGroup = DispatchGroup()
    
    for userId in groupMessage.userIds {
        dispatchGroup.enter()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, var userData = document.data(), var groupMessages = userData["groupMessages"] as? [[String: Any]] {
                if let index = groupMessages.firstIndex(where: { $0["id"] as? String == groupMessage.id }) {
                    groupMessages[index]["userIds"] = allIds
                } else {
                    // 新しいグループメッセージを追加
                    groupMessages.append(["id": groupMessage.id, "userIds": allIds])
                }
                userData["groupMessages"] = groupMessages
                
                db.collection("users").document(userId).updateData(userData) { error in
                    if let error = error {
                        print("Failed to update group message for user \(userId): \(error.localizedDescription)")
                    } else {
                        print("Group message updated successfully for user \(userId)")
                    }
                    dispatchGroup.leave()
                }
            } else {
                print("Failed to fetch user data for user \(userId): \(error?.localizedDescription ?? "Unknown error")")
                dispatchGroup.leave()
            }
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        print("All updates completed")
        presentationMode.wrappedValue.dismiss()
        isAdding = false
    }
}
}